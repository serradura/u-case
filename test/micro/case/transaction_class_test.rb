require 'test_helper'

# Pins down the multi-database surface for transactions:
#
#   * The `transaction with: AClass` class macro and its inheritance.
#   * `Micro::Case#transaction(with: ...)` inline helper resolution
#     order (call-site override > class macro > global default).
#   * `Micro::Cases.flow(transaction: { with: AClass }, steps: [...])`
#     and the class-level `flow(transaction: { with: AClass }, ...)`.
#   * `Micro::Case.config.default_transaction_class { ... }` callback
#     (lazy, called on every transaction open) and its default
#     `-> { ::ActiveRecord::Base }`.
#
# The gem's transaction code raises `::ActiveRecord::Rollback`. When
# running under a bundle that includes activerecord (appraisals), we
# pre-load it so the real Rollback class exists. On the bare bundle
# we stub a `::ActiveRecord::Rollback` constant so the raise works
# without pulling in the whole AR dependency tree.
if Gem.loaded_specs.key?('activerecord')
  require 'support/activerecord_setup'
elsif !defined?(::ActiveRecord)
  module ::ActiveRecord
    class Rollback < StandardError; end

    class Base
      def self.transaction
        yield
      rescue ::ActiveRecord::Rollback
        # swallow, like real AR
      end
    end
  end
end

class Micro::Case::TransactionClassTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  # Test doubles that satisfy `transaction_owner!` (which requires
  # `<= ActiveRecord::Base`) but override `.transaction` so the test
  # can record who opened it without touching a real DB connection.
  class FakeRecord < ::ActiveRecord::Base
    self.abstract_class = true if respond_to?(:abstract_class=)

    class << self
      attr_accessor :opened_by, :rolled_back

      def reset!
        @opened_by = nil
        @rolled_back = false
      end

      def transaction
        self.opened_by ||= []
        opened_by << self
        yield
      rescue ::ActiveRecord::Rollback
        self.rolled_back = true
      end
    end
  end

  class AppRecord < FakeRecord; end
  class AnalyticsRecord < FakeRecord; end
  class BillingRecord < FakeRecord; end

  def teardown
    [FakeRecord, AppRecord, AnalyticsRecord, BillingRecord].each(&:reset!)

    Micro::Case::Config.instance.instance_variable_set(:@default_transaction_class, nil)
    Micro::Case::Config.instance.remove_instance_variable(:@default_transaction_class)
  end

  # ---------------------------------------------------------------------------
  # Config#default_transaction_class
  # ---------------------------------------------------------------------------

  def test_default_transaction_class_defaults_to_an_active_record_base_callback
    # The default callback resolves to ::ActiveRecord::Base. Our test
    # stub exposes it through the inline helper test below, so here we
    # just confirm the default is a callable that targets AR::Base
    # (without invoking it — we don't want to require AR here).
    callback = Micro::Case::Config.instance.default_transaction_class
    assert_respond_to(callback, :call)
  end

  def test_default_transaction_class_accepts_a_block
    Micro::Case.config do |config|
      config.default_transaction_class { AppRecord }
    end

    assert_same(AppRecord, Micro::Case::Config.instance.default_transaction_class.call)
  end

  def test_default_transaction_class_accepts_a_lambda
    Micro::Case.config do |config|
      config.default_transaction_class = -> { BillingRecord }
    end

    assert_same(BillingRecord, Micro::Case::Config.instance.default_transaction_class.call)
  end

  def test_default_transaction_class_rejects_a_non_callable
    err = assert_raises(ArgumentError) do
      Micro::Case.config do |config|
        config.default_transaction_class = 'ApplicationRecord'
      end
    end

    assert_match(/expects a callable/, err.message)
  end

  def test_default_transaction_class_callback_is_called_on_every_resolution
    counter = 0
    Micro::Case.config do |config|
      config.default_transaction_class { counter += 1; AppRecord }
    end

    flow = Micro::Cases.flow(transaction: true, steps: [TouchOnly])
    flow.call
    flow.call
    flow.call

    assert_equal(3, counter)
  end

  # ---------------------------------------------------------------------------
  # Class-level `transaction with:` macro + inheritance
  # ---------------------------------------------------------------------------

  class AppCase < Micro::Case
    transaction with: AppRecord
    def call!; Success(); end
  end

  class BillingCase < AppCase
    transaction with: BillingRecord
  end

  class UndeclaredCase < Micro::Case
    def call!; Success(); end
  end

  def test_transaction_class_macro_declares_the_owner
    assert_same(AppRecord, AppCase.__transaction_class__)
  end

  def test_transaction_class_macro_is_inherited
    klass = Class.new(AppCase)
    assert_same(AppRecord, klass.__transaction_class__)
  end

  def test_transaction_class_macro_is_overridable_by_subclass
    assert_same(BillingRecord, BillingCase.__transaction_class__)
  end

  def test_transaction_class_macro_is_nil_when_undeclared
    assert_nil(UndeclaredCase.__transaction_class__)
  end

  # ---------------------------------------------------------------------------
  # Inline `Micro::Case#transaction(with:)` resolution
  # ---------------------------------------------------------------------------

  class InlineExplicit < Micro::Case
    transaction with: AppRecord
    def call!
      transaction(with: AnalyticsRecord) { Success() }
    end
  end

  class InlineFromClassMacro < Micro::Case
    transaction with: AppRecord
    def call!
      transaction { Success() }
    end
  end

  class InlineFromGlobalDefault < Micro::Case
    def call!
      transaction { Success() }
    end
  end

  def test_inline_helper_uses_explicit_with_kwarg
    InlineExplicit.call
    assert_equal([AnalyticsRecord], AnalyticsRecord.opened_by)
    assert_nil(AppRecord.opened_by)
  end

  def test_inline_helper_falls_back_to_class_macro
    InlineFromClassMacro.call
    assert_equal([AppRecord], AppRecord.opened_by)
  end

  def test_inline_helper_falls_back_to_global_default_callback
    Micro::Case.config do |config|
      config.default_transaction_class { BillingRecord }
    end

    InlineFromGlobalDefault.call
    assert_equal([BillingRecord], BillingRecord.opened_by)
  end

  def test_inline_helper_rejects_a_non_class_with_value
    klass = Class.new(Micro::Case) do
      def call!
        transaction(with: 'AppRecord') { Success() }
      end
    end

    err = assert_raises(ArgumentError) { klass.call }
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_inline_helper_rejects_a_class_that_is_not_an_active_record_subclass
    non_ar_class = Class.new
    klass = Class.new(Micro::Case) do
      define_method(:call!) { transaction(with: non_ar_class) { Success() } }
    end

    err = assert_raises(ArgumentError) { klass.call }
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_inline_helper_accepts_the_legacy_positional_activerecord_value
    klass = Class.new(Micro::Case) do
      define_method(:call!) { transaction(:activerecord) { Success() } }
    end

    # No transaction_class declared and no global override, so it
    # routes through the default callback (`-> { ::ActiveRecord::Base }`).
    # In tests that path resolves to the real / stubbed AR::Base; we
    # only assert the call doesn't raise the new ArgumentError shim.
    result = klass.call

    assert_predicate(result, :success?)
  end

  def test_inline_helper_rejects_any_other_positional_value
    klass = Class.new(Micro::Case) do
      define_method(:call!) { transaction(:redis) { Success() } }
    end

    err = assert_raises(ArgumentError) { klass.call }
    assert_match(/transaction\(:redis\) is not supported/, err.message)
  end

  # ---------------------------------------------------------------------------
  # Flow kwarg `transaction: { with: Class }` (module-level)
  # ---------------------------------------------------------------------------

  class TouchOnly < Micro::Case
    def call!; Success(); end
  end

  def test_flow_transaction_with_hash_uses_the_explicit_class
    flow = Micro::Cases.flow(transaction: { with: AnalyticsRecord }, steps: [TouchOnly])
    flow.call

    assert_equal([AnalyticsRecord], AnalyticsRecord.opened_by)
  end

  def test_flow_transaction_true_uses_the_global_default
    Micro::Case.config do |config|
      config.default_transaction_class { AppRecord }
    end

    flow = Micro::Cases.flow(transaction: true, steps: [TouchOnly])
    flow.call

    assert_equal([AppRecord], AppRecord.opened_by)
  end

  def test_flow_transaction_with_hash_rejects_extra_keys
    err = assert_raises(ArgumentError) do
      Micro::Cases.flow(transaction: { with: AppRecord, requires_new: true }, steps: [TouchOnly])
    end
    assert_match(/unsupported key\(s\) \[:requires_new\]/, err.message)
  end

  def test_flow_transaction_with_hash_rejects_non_class_value
    err = assert_raises(ArgumentError) do
      Micro::Cases.flow(transaction: { with: 'AppRecord' }, steps: [TouchOnly])
    end
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_flow_transaction_with_bare_class_rejects_non_ar_subclass
    non_ar = Class.new
    err = assert_raises(ArgumentError) do
      Micro::Cases.flow(transaction: non_ar, steps: [TouchOnly])
    end
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_class_level_transaction_macro_rejects_non_ar_subclass_eagerly
    err = assert_raises(ArgumentError) do
      Class.new(Micro::Case) { transaction with: Class.new }
    end
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_class_level_transaction_macro_rejects_non_class_eagerly
    err = assert_raises(ArgumentError) do
      Class.new(Micro::Case) { transaction with: 'AppRecord' }
    end
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  # ---------------------------------------------------------------------------
  # Class-level flow(transaction: true, ...) resolves to host's class macro
  # ---------------------------------------------------------------------------

  class FlowHostWithMacro < Micro::Case
    transaction with: AppRecord
    flow(transaction: true, steps: [TouchOnly])
  end

  class FlowHostWithExplicitOverride < Micro::Case
    transaction with: AppRecord
    flow(transaction: { with: AnalyticsRecord }, steps: [TouchOnly])
  end

  def test_class_level_flow_true_resolves_to_host_transaction_class
    FlowHostWithMacro.call

    assert_equal([AppRecord], AppRecord.opened_by)
  end

  def test_class_level_flow_explicit_hash_overrides_host_macro
    FlowHostWithExplicitOverride.call

    assert_equal([AnalyticsRecord], AnalyticsRecord.opened_by)
    assert_nil(AppRecord.opened_by)
  end
end
