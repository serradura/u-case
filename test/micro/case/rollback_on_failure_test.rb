require 'test_helper'

# `Micro::Case#rollback_on_failure` is `alias_method :rollback_on_failure, :transaction`.
# The alias exists so use cases that declare `attribute :transaction` (and would
# otherwise shadow the helper with the attribute reader) keep a verbose,
# unambiguous way to reach the rollback semantics.
#
# These tests pin down two things:
#
#   1. Behavioral parity with `#transaction` — same resolution order
#      (call-site `with:` > class macro > global default), same
#      `transaction(:activerecord)` back-compat shim, same `ArgumentError`
#      on any other positional value, same rollback-on-failure semantics.
#   2. The attribute-shadowing regression — `attribute :transaction`
#      shadows `#transaction` (by design — the attribute reader wins),
#      but `#rollback_on_failure` is untouched and still rolls back.
if Gem.loaded_specs.key?('activerecord')
  require 'support/activerecord_setup'

class Micro::Case::RollbackOnFailureTest < Minitest::Test
  # ----- FakeRecord stubs -----
  # Same pattern as TransactionClassTest: subclass AR::Base (so
  # `transaction_owner!` accepts it) and override `.transaction` so we
  # can record who opened it without touching a real connection.
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

    Widget.delete_all

    if Micro::Case::Config.instance.instance_variable_defined?(:@default_transaction_class)
      Micro::Case::Config.instance.remove_instance_variable(:@default_transaction_class)
    end
  end

  # ---------------------------------------------------------------------------
  # Alias identity
  # ---------------------------------------------------------------------------

  def test_rollback_on_failure_is_an_alias_of_transaction
    # `alias_method` makes the two names share the same underlying
    # method object. We check both that the symbols resolve to the
    # same UnboundMethod and that aliasing is reflected in #aliases.
    transaction_method = Micro::Case.instance_method(:transaction)
    rollback_method    = Micro::Case.instance_method(:rollback_on_failure)

    assert_equal(transaction_method, rollback_method)
  end

  # ---------------------------------------------------------------------------
  # Behavioral parity with `#transaction` — no DB required (FakeRecord)
  # ---------------------------------------------------------------------------

  class InlineExplicitViaAlias < Micro::Case
    transaction with: AppRecord
    def call!
      rollback_on_failure(with: AnalyticsRecord) { Success() }
    end
  end

  class InlineFromClassMacroViaAlias < Micro::Case
    transaction with: AppRecord
    def call!
      rollback_on_failure { Success() }
    end
  end

  class InlineFromGlobalDefaultViaAlias < Micro::Case
    def call!
      rollback_on_failure { Success() }
    end
  end

  def test_alias_uses_explicit_with_kwarg
    InlineExplicitViaAlias.call
    assert_equal([AnalyticsRecord], AnalyticsRecord.opened_by)
    assert_nil(AppRecord.opened_by)
  end

  def test_alias_falls_back_to_class_macro
    InlineFromClassMacroViaAlias.call
    assert_equal([AppRecord], AppRecord.opened_by)
  end

  def test_alias_falls_back_to_global_default_callback
    Micro::Case.config do |config|
      config.default_transaction_class { BillingRecord }
    end

    InlineFromGlobalDefaultViaAlias.call
    assert_equal([BillingRecord], BillingRecord.opened_by)
  end

  def test_alias_rejects_a_non_class_with_value
    klass = Class.new(Micro::Case) do
      def call!
        rollback_on_failure(with: 'AppRecord') { Success() }
      end
    end

    err = assert_raises(ArgumentError) { klass.call }
    assert_match(/must be a subclass of ActiveRecord::Base/, err.message)
  end

  def test_alias_accepts_the_legacy_positional_activerecord_value
    klass = Class.new(Micro::Case) do
      define_method(:call!) { rollback_on_failure(:activerecord) { Success() } }
    end

    # No transaction_class declared and no global override, so it
    # routes through the default callback (`-> { ::ActiveRecord::Base }`).
    # We only assert the call doesn't raise the new ArgumentError shim.
    result = klass.call

    assert_predicate(result, :success?)
  end

  def test_alias_rejects_any_other_positional_value
    klass = Class.new(Micro::Case) do
      define_method(:call!) { rollback_on_failure(:redis) { Success() } }
    end

    err = assert_raises(ArgumentError) { klass.call }
    assert_match(/transaction\(:redis\) is not supported/, err.message)
  end

  # ---------------------------------------------------------------------------
  # Real-AR rollback semantics + the attribute-shadowing regression
  # ---------------------------------------------------------------------------
  # The `tx_widgets` table is set up by `support/activerecord_setup.rb`
  # and shared across transaction test files.

  class Widget < ::ActiveRecord::Base
    self.table_name = 'tx_widgets'
  end

  class CreateWidgetOk < Micro::Case
    def call!
      rollback_on_failure {
        Widget.create!(name: 'ok')
        Success()
      }
    end
  end

  class CreateWidgetFails < Micro::Case
    def call!
      rollback_on_failure {
        Widget.create!(name: 'to-be-rolled-back')
        Failure(:nope)
      }
    end
  end

  def test_alias_commits_when_block_returns_success
    result = CreateWidgetOk.call

    assert_predicate(result, :success?)
    assert_equal(1, Widget.where(name: 'ok').count)
  end

  def test_alias_rolls_back_when_block_returns_failure
    result = CreateWidgetFails.call

    assert_predicate(result, :failure?)
    assert_equal(0, Widget.where(name: 'to-be-rolled-back').count)
  end

  # The whole point of the alias: a use case that needs an attribute
  # called `transaction` (a domain object, nothing to do with DB) can
  # still reach the rollback helper through `rollback_on_failure`.
  # The `transaction` attribute reader is intentionally left to win
  # over the inherited `#transaction` method — that's standard
  # u-attributes behavior — so the alias is the documented escape
  # hatch.
  class RefundPayment < Micro::Case
    attribute :transaction

    def call!
      rollback_on_failure {
        Widget.create!(name: "refund:#{transaction}")
        Failure(:refund_failed)
      }
    end
  end

  class RefundPaymentSuccess < Micro::Case
    attribute :transaction

    def call!
      rollback_on_failure {
        Widget.create!(name: "refund:#{transaction}")
        Success()
      }
    end
  end

  def test_alias_works_when_transaction_attribute_shadows_the_helper
    result = RefundPayment.call(transaction: 'tx-123')

    assert_predicate(result, :failure?)
    assert_equal(0, Widget.where(name: 'refund:tx-123').count)
  end

  def test_alias_commits_when_transaction_attribute_shadows_the_helper_and_block_succeeds
    result = RefundPaymentSuccess.call(transaction: 'tx-456')

    assert_predicate(result, :success?)
    assert_equal(1, Widget.where(name: 'refund:tx-456').count)
  end

  def test_transaction_attribute_reader_is_untouched_by_the_alias
    # Sanity check: declaring `attribute :transaction` still shadows
    # the `#transaction` helper (by design — u-attributes generates
    # the reader on the instance, which beats the inherited method).
    # `rollback_on_failure` is the escape hatch.
    klass = Class.new(Micro::Case) do
      attribute :transaction

      def call!
        Success result: { reader_value: transaction }
      end
    end

    result = klass.call(transaction: 'domain-object')

    assert_predicate(result, :success?)
    assert_equal('domain-object', result[:reader_value])
  end
end

end # if Gem.loaded_specs.key?('activerecord')
