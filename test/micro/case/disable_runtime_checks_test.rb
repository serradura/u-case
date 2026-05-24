require 'test_helper'

class Micro::Case::DisableRuntimeChecksTest < Minitest::Test
  i_suck_and_my_tests_are_order_dependent!

  def teardown
    Micro::Case.config do |config|
      config.disable_runtime_checks = false
    end
  end

  def test_the_default_value_is_false
    assert_equal(false, Micro::Case::Config.instance.disable_runtime_checks)
  end

  def test_it_only_accepts_a_boolean_value
    assert_raises_with_message(
      Kind::Error,
      '"yes" expected to be a kind of Boolean'
    ) do
      Micro::Case.config do |config|
        config.disable_runtime_checks = 'yes'
      end
    end
  end

  def test_the_default_check_module_is_enabled
    assert_same(Micro::Case::Check::Enabled, Micro::Case.check)
  end

  def test_setting_to_true_swaps_to_the_disabled_check_module
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    assert_same(Micro::Case::Check::Disabled, Micro::Case.check)
  end

  def test_setting_back_to_false_restores_the_enabled_check_module
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    Micro::Case.config do |config|
      config.disable_runtime_checks = false
    end

    assert_same(Micro::Case::Check::Enabled, Micro::Case.check)
  end

  def test_disabled_and_enabled_modules_expose_the_same_methods
    enabled_methods = (Micro::Case::Check::Enabled.methods - Module.methods).sort
    disabled_methods = (Micro::Case::Check::Disabled.methods - Module.methods).sort

    assert_equal(enabled_methods, disabled_methods)
  end

  class UseCaseReturningNonResult < Micro::Case
    def call!; :not_a_result; end
  end

  def test_disabling_skips_the_unexpected_result_check
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    assert_equal(:not_a_result, UseCaseReturningNonResult.call)
  end

  def test_enabled_raises_for_the_unexpected_result_check
    err = assert_raises(Micro::Case::Error::UnexpectedResult) do
      UseCaseReturningNonResult.call
    end

    assert_match(/UseCaseReturningNonResult#call!/, err.message)
  end

  def test_disabling_skips_the_invalid_use_case_check_in_flow_build
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    # `Cases.flow([Symbol])` would normally raise InvalidUseCases
    assert_kind_of(Micro::Cases::Flow, Micro::Cases.flow([:not_a_use_case]))
  end

  def test_enabled_raises_for_the_invalid_use_case_check_in_flow_build
    assert_raises(Micro::Cases::Error::InvalidUseCases) do
      Micro::Cases.flow([:not_a_use_case])
    end
  end

  def test_disabling_skips_the_invalid_args_check_in_map_build
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    # `Cases.map([Symbol])` would normally raise InvalidUseCases
    assert_kind_of(Micro::Cases::Map, Micro::Cases.map([:not_a_use_case]))
  end

  def test_enabled_raises_for_the_invalid_args_check_in_map_build
    assert_raises(Micro::Cases::Error::InvalidUseCases) do
      Micro::Cases.map([:not_a_use_case])
    end
  end

  class UseCaseForThenTest < Micro::Case
    def call!; Success(); end
  end

  def test_disabling_skips_the_then_invocation_check
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    # `Micro::Case.then(non_use_case)` would normally raise InvalidInvocationOfTheThenMethod
    # With checks off the bad value is forwarded, and the downstream Result#then
    # is what now raises (its check is also off, so the eventual error is a TypeError).
    err = assert_raises(StandardError) do
      UseCaseForThenTest.then(:not_a_use_case)
    end

    refute_kind_of(Micro::Case::Error::InvalidInvocationOfTheThenMethod, err)
  end

  def test_enabled_raises_for_the_then_invocation_check
    assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) do
      UseCaseForThenTest.then(:not_a_use_case)
    end
  end

  def test_real_use_case_still_works_when_checks_are_disabled
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    klass = Class.new(Micro::Case) do
      attribute :n
      def call!; Success(result: { v: n * 2 }); end
    end

    result = klass.call(n: 3)

    assert_predicate(result, :success?)
    assert_equal({ v: 6 }, result.value)
  end

  class UseCaseWithBadContract < Micro::Case
    results do |on|
      on.success(result: [:value])
      on.failure(:known)
    end

    def call!
      Success(:undeclared, result: { value: 1 })
    end
  end

  def test_disabling_skips_the_results_contract_check
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    result = UseCaseWithBadContract.call

    assert_predicate(result, :success?)
    assert_equal(:undeclared, result.type)
  end

  def test_enabled_raises_for_the_results_contract_check
    assert_raises(Micro::Case::Error::UnexpectedResultType) do
      UseCaseWithBadContract.call
    end
  end

  class NoopStep < Micro::Case
    def call!; Success(); end
  end

  def test_disabling_skips_the_flow_steps_kwarg_check
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    # Normally raises ArgumentError because args and steps: are mutually exclusive.
    flow = Micro::Cases.flow([NoopStep], steps: [NoopStep])

    assert_kind_of(Micro::Cases::Flow, flow)
  end

  def test_enabled_raises_for_the_flow_steps_kwarg_check
    err = assert_raises(ArgumentError) do
      Micro::Cases.flow([NoopStep], steps: [NoopStep])
    end

    assert_match(/Micro::Cases.flow accepts a positional collection OR `steps:`, not both/, err.message)
  end

  def test_disabling_skips_the_transaction_kwarg_check
    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    # Normally raises ArgumentError because only `true` is supported today.
    flow = Micro::Cases.flow(transaction: :sequel, steps: [NoopStep])

    assert_kind_of(Micro::Cases::Flow, flow)
  end

  def test_enabled_raises_for_the_transaction_kwarg_check
    err = assert_raises(ArgumentError) do
      Micro::Cases.flow(transaction: :sequel, steps: [NoopStep])
    end

    assert_match(/transaction: :sequel is not supported/, err.message)
  end

  def test_disabling_skips_the_activerecord_loaded_check
    skip 'activerecord is loaded — checks_disabled path is unreachable in this bundle' if defined?(::ActiveRecord::Base)

    Micro::Case.config do |config|
      config.disable_runtime_checks = true
    end

    flow = Micro::Cases.flow(transaction: true, steps: [NoopStep])

    # Without the check, calling reaches ::ActiveRecord::Base and raises
    # NameError instead of the curated TransactionAdapterMissing.
    assert_raises(NameError) { flow.call }
  end

  def test_enabled_raises_for_the_activerecord_loaded_check
    skip 'activerecord is loaded — TransactionAdapterMissing path is unreachable in this bundle' if defined?(::ActiveRecord::Base)

    flow = Micro::Cases.flow(transaction: true, steps: [NoopStep])

    assert_raises(Micro::Cases::Error::TransactionAdapterMissing) { flow.call }
  end
end
