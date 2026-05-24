require 'test_helper'

class Micro::Case::AttributesAcceptTest < Minitest::Test
  class Greet < Micro::Case
    attribute :name, accept: String
    attribute :age,  accept: Integer, allow_nil: true

    def call!
      Success(result: { msg: "Hello, #{name}!" })
    end
  end

  def test_enable_attributes_accept_is_true_by_default
    assert_equal(true, Micro::Case::Config.instance.enable_attributes_accept)
  end

  def test_accept_feature_is_included_in_micro_case
    assert_includes(Micro::Case.ancestors, Micro::Attributes::Features::Accept)
  end

  def test_success_when_attributes_are_accepted
    result = Greet.call(name: 'Bob')

    assert_success_result(result, value: { msg: 'Hello, Bob!' })
  end

  def test_success_with_allow_nil_attribute
    result = Greet.call(name: 'Bob', age: nil)

    assert_success_result(result, value: { msg: 'Hello, Bob!' })
  end

  def test_failure_when_attribute_is_rejected
    result = Greet.call(name: 42)

    assert_failure_result(result, type: :invalid_attributes)
    assert_equal({ 'name' => 'expected to be a kind of String' }, result.value[:errors])
  end

  def test_failure_collects_multiple_rejection_errors
    result = Greet.call(name: 42, age: 'twenty')

    assert_failure_result(result, type: :invalid_attributes)
    assert_equal(
      { 'name' => 'expected to be a kind of String', 'age' => 'expected to be a kind of Integer' },
      result.value[:errors]
    )
  end

  def test_no_failure_when_attributes_are_accepted_and_call_runs
    refute_predicate(Greet.call(name: 'Bob'), :failure?)
  end

  class ResetConfigAfterTest
    def self.with(value)
      Micro::Case::Config.instance.enable_attributes_accept = value
      yield
    ensure
      Micro::Case::Config.instance.enable_attributes_accept = true
    end
  end

  def test_when_enable_attributes_accept_is_false_use_case_does_not_auto_fail
    ResetConfigAfterTest.with(false) do
      # Errors are still collected by u-attributes, but the use case is not auto-failed
      result = Greet.call(name: 42)

      assert_predicate(result, :success?)
    end
  end
end
