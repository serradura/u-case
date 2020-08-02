require 'test_helper'

class Micro::Case::Result::StepsTest < Minitest::Test
  class ThirdSum < Micro::Case
    attribute :sum

    def call!
      Success :third_sum, result: {
        sum: sum + 0.5
      }
    end
  end

  class DoSomeSumUsingThen < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes
        .then(-> { sum_a_and_b })
        .then(-> data { add(data, number: 3) })
        .then(ThirdSum)
    end

    private

      def validate_attributes
        Kind.of?(Numeric, a, b) ? Success(:valid) : Failure()
      end

      def sum_a_and_b
        Success :first_sum, result: { sum: a + b }
      end

      def add(data, number:)
        Success :second_sum, result: {
          sum: data[:sum] + number
        }
      end
  end

  def test_the_then_method_with_lambdas
    resulta = DoSomeSumUsingThen.call(a: 1, b: 2)

    assert_success_result(resulta, value: { sum: 6.5 })

    [
      {
        use_case: { class: DoSomeSumUsingThen, attributes: { a: 1, b: 2 } },
        success: { type: :valid, result: { valid: true } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: DoSomeSumUsingThen, attributes: { a: 1, b: 2 } },
        success: { type: :first_sum, result: { sum: 3 } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: DoSomeSumUsingThen, attributes: { a: 1, b: 2 } },
        success: { type: :second_sum, result: { sum: 6 } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: ThirdSum, attributes: { sum: 6 } },
        success: { type: :third_sum, result: { sum: 6.5 } },
        accessible_attributes: [:a, :b, :sum]
      }
    ].each_with_index do |transition, index|
      assert_equal(transition, resulta.transitions[index])
    end

    # ---

    resultb = DoSomeSumUsingThen.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })

    [
      {
        use_case: { class: DoSomeSumUsingThen, attributes: { a: 1, b: '2' } },
        failure: { type: :error, result: { error: true } },
        accessible_attributes: [:a, :b]
      }
    ].each_with_index do |transition, index|
      assert_equal(transition, resultb.transitions[index])
    end
  end

  class MultiplyByTwoUsingThen < Micro::Case
    attributes :number

    def call!
      validate_number
        .then(-> { number.to_f })
        .then(-> data { multiply_by_two(data[:number]) })
    end

    private

    def validate_number
      Kind.of?(Numeric, number) ? Success(:valid) : Failure()
    end

    def multiply_by_two(number)
      Success(result: { number: number * 2 })
    end
  end

  def test_the_then_method_error_when_a_lambda_doesnt_return_a_result
    assert_raises_with_message(
      Micro::Case::Error::UnexpectedResult,
      /Micro::Case::Result#then\(-> {}\) must return an instance of Micro::Case::Result/
    ) { MultiplyByTwoUsingThen.call(number: 2) }
  end

  class DoSomeSumUsingPipe < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes \
        | -> { sum_a_and_b } \
        | -> data { add(data, number: 4) } \
        | ThirdSum
    end

    private

      def validate_attributes
        Kind.of?(Numeric, a, b) ? Success(:valid) : Failure()
      end

      def sum_a_and_b
        Success :first_sum, result: { sum: a + b }
      end

      def add(data, number:)
        Success :second_sum, result: { sum: data[:sum] + number }
      end
  end

  def test_the_pipe_method_with_lambdas
    resulta = DoSomeSumUsingPipe.call(a: 1, b: 2)

    assert_success_result(resulta, value: { sum: 7.5 })

    [
      {
        use_case: { class: DoSomeSumUsingPipe, attributes: { a: 1, b: 2 } },
        success: { type: :valid, result: { valid: true } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: DoSomeSumUsingPipe, attributes: { a: 1, b: 2 } },
        success: { type: :first_sum, result: { sum: 3 } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: DoSomeSumUsingPipe, attributes: { a: 1, b: 2 } },
        success: { type: :second_sum, result: { sum: 7 } },
        accessible_attributes: [:a, :b]
      },
      {
        use_case: { class: ThirdSum, attributes: { sum: 7 } },
        success: { type: :third_sum, result: { sum: 7.5 } },
        accessible_attributes: [:a, :b, :sum]
      }
    ].each_with_index do |transition, index|
      assert_equal(transition, resulta.transitions[index])
    end

    # ---

    resultb = DoSomeSumUsingPipe.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })

    [
      {
        use_case: { class: DoSomeSumUsingPipe, attributes: { a: 1, b: '2' } },
        failure: { type: :error, result: { error: true } },
        accessible_attributes: [:a, :b]
      }
    ].each_with_index do |transition, index|
      assert_equal(transition, resultb.transitions[index])
    end
  end

  class MultiplyByTwoUsingPipe < Micro::Case
    attributes :number

    def call!
      validate_number \
        | -> { number.to_f } \
        | -> data { multiply_by_two(data[:number]) }
    end

    private

    def validate_number
      Kind.of?(Numeric, number) ? Success(:valid) : Failure()
    end

    def multiply_by_two(number)
      Success(result: { number: number * 2 })
    end
  end

  def test_the_pipe_method_error_when_a_lambda_doesnt_return_a_result
    assert_raises_with_message(
      Micro::Case::Error::UnexpectedResult,
      /Micro::Case::Result#| -> {} must return an instance of Micro::Case::Result/
    ) { MultiplyByTwoUsingPipe.call(number: 2) }
  end
end
