require 'test_helper'

class Micro::Case::ResultsContractTest < Minitest::Test
  class Divide < Micro::Case
    attributes :a, :b

    results do |on|
      on.failure(:attributes_must_be_numbers)
      on.failure(:division_by_zero)

      on.success(result: [:division])
    end

    def call!
      return Failure(:attributes_must_be_numbers) unless Kind.of?(Numeric, a, b)
      return Failure(:division_by_zero) if b == 0

      Success result: { division: a / b }
    end
  end

  def test_a_declared_success_with_required_keys_is_accepted
    result = Divide.call(a: 10, b: 2)

    assert_predicate(result, :success?)
    assert_equal(:ok, result.type)
    assert_equal(5, result[:division])
  end

  def test_a_declared_failure_type_without_keys_is_accepted
    result1 = Divide.call(a: 'a', b: 2)
    assert_predicate(result1, :failure?)
    assert_equal(:attributes_must_be_numbers, result1.type)

    result2 = Divide.call(a: 10, b: 0)
    assert_predicate(result2, :failure?)
    assert_equal(:division_by_zero, result2.type)
  end

  class Wrong < Micro::Case
    attributes :a

    results do |on|
      on.failure(:known)
      on.success(result: [:value])
    end

    def call!
      case a
      when :undeclared_success then Success(:other, result: { value: 1 })
      when :undeclared_failure then Failure(:other)
      when :missing_success_keys then Success(result: { wrong: 1 })
      when :missing_failure_keys then Failure(:known)
      else Success(result: { value: 1 })
      end
    end
  end

  def test_an_undeclared_success_type_raises
    error = assert_raises(Micro::Case::Error::UnexpectedResultType) do
      Wrong.call(a: :undeclared_success)
    end

    assert_match(/Wrong/, error.message)
    assert_match(/success type :other/, error.message)
    assert_match(/:ok/, error.message)
  end

  def test_an_undeclared_failure_type_raises
    error = assert_raises(Micro::Case::Error::UnexpectedResultType) do
      Wrong.call(a: :undeclared_failure)
    end

    assert_match(/Wrong/, error.message)
    assert_match(/failure type :other/, error.message)
    assert_match(/:known/, error.message)
  end

  def test_missing_required_success_keys_raises
    error = assert_raises(Micro::Case::Error::MissingResultKeys) do
      Wrong.call(a: :missing_success_keys)
    end

    assert_match(/Wrong/, error.message)
    assert_match(/success.*:ok/, error.message)
    assert_match(/:value/, error.message)
  end

  class WithKeyedFailure < Micro::Case
    attributes :reason

    results do |on|
      on.failure(:invalid, result: [:reason])
      on.success(result: [:value])
    end

    def call!
      if reason
        Failure(:invalid, result: { reason: reason })
      else
        Success(result: { value: 1 })
      end
    end
  end

  def test_required_failure_keys_are_validated
    result = WithKeyedFailure.call(reason: 'bad')
    assert_predicate(result, :failure?)
    assert_equal('bad', result[:reason])
  end

  class MissingFailureKey < Micro::Case
    results do |on|
      on.failure(:invalid, result: [:reason])
    end

    def call!
      Failure(:invalid)
    end
  end

  def test_missing_required_failure_keys_raises
    error = assert_raises(Micro::Case::Error::MissingResultKeys) do
      MissingFailureKey.call
    end

    assert_match(/failure.*:invalid/, error.message)
    assert_match(/:reason/, error.message)
  end

  class NoContract < Micro::Case
    def call!
      Success(:anything, result: { whatever: 1 })
    end
  end

  def test_no_contract_means_no_validation
    result = NoContract.call
    assert_predicate(result, :success?)
    assert_equal(:anything, result.type)
  end

  class InheritedContract < Divide
  end

  def test_subclasses_inherit_the_contract
    result = InheritedContract.call(a: 10, b: 2)
    assert_predicate(result, :success?)
    assert_equal(5, result[:division])

    assert_raises(Micro::Case::Error::UnexpectedResultType) do
      Class.new(Divide) do
        def call!
          Success(:something_else, result: { division: 1 })
        end
      end.call(a: 1, b: 1)
    end
  end

  class ExtraKeysAllowed < Micro::Case
    results do |on|
      on.success(result: [:value])
    end

    def call!
      Success(result: { value: 1, extra: 2 })
    end
  end

  def test_extra_keys_beyond_required_are_allowed
    result = ExtraKeysAllowed.call
    assert_predicate(result, :success?)
    assert_equal(1, result[:value])
    assert_equal(2, result[:extra])
  end

  class SafeWithContract < Micro::Case::Safe
    results do |on|
      on.success(result: [:value])
      on.failure(:bad)
    end

    def call!
      raise 'boom'
    end
  end

  def test_safe_exception_failures_bypass_the_contract
    result = SafeWithContract.call
    assert_predicate(result, :failure?)
    assert_equal(:exception, result.type)
    assert_kind_of(RuntimeError, result[:exception])
  end
end
