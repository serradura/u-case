require 'test_helper'

class Micro::Case::Result::ThenTest < Minitest::Test
  def build_result(success:, value:, type:, use_case: nil)
    result = Micro::Case::Result.new
    result.__set__(success, value, type, use_case || Micro::Case.new({}))
    result
  end

  def failure_result(options = {})
    build_result(**{ type: :error }.merge(options).merge(success: false))
  end

  def success_result(options = {})
    build_result(**{ type: :ok }.merge(options).merge(success: true))
  end

  if RUBY_VERSION < '2.5.0'
    def test_not_implemented_error
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_raises(NotImplementedError) { result1.then { 0 } }
      assert_raises(NotImplementedError) { result2.then { 0 } }

      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) { 0 } }
      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) { 0 } }
    end
  else
    def test_not_implemented_error
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) { 0 } }
      assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) { 0 } }
    end

    def test_the_method_then_with_a_block
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      result1.then { |result| assert_equal(result1, result) }
      result2.then { |result| assert_equal(result2, result) }
    end

    def test_the_method_then_without_a_block_and_an_argument
      result1 = success_result(value: 0)
      result2 = failure_result(value: 1)

      assert_instance_of(Enumerator, result1.then)
      assert_instance_of(Enumerator, result2.then)
    end
  end

  def test_not_implemented_error_when_call_the_then_method_without_a_use_case
    result1 = success_result(value: 0)
    result2 = failure_result(value: 1)

    assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result1.then(1) }
    assert_raises(Micro::Case::Error::InvalidInvocationOfTheThenMethod) { result2.then(1) }
  end

  class Add3 < Micro::Case
    attribute :number

    def call!
      Success { { number: number + 3 } }
    end
  end

  def test_the_output_when_call_the_then_method_with_a_use_case
    result1 = success_result(value: { number: 0 }).then(Add3)

    assert_success_result(result1, value: { number: 3 })

    # ---

    result2 = failure_result(value: { number: 1 }).then(Add3)

    assert_failure_result(result2, value: { number: 1 })
  end
end
