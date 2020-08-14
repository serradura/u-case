require 'test_helper'

class Micro::Case::InternalStepsWithLambdasTest < Minitest::Test
  class SumHalf < Micro::Case
    attribute :sum

    def call!
      Success :third_sum, result: {
        sum: sum + 0.5
      }
    end
  end

  class DoSomeSumUsingThenWithLambdas < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes
        .then(-> { sum_a_and_b })
        .then(-> data { add(data, number: 3) })
        .then(SumHalf)
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
    resulta = DoSomeSumUsingThenWithLambdas.call(a: 1, b: 2)

    assert_success_result(resulta, value: { sum: 6.5 })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: DoSomeSumUsingThenWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :valid, result: { valid: true } },
          accessible_attributes: [:a, :b]
        },
        {
          use_case: { class: DoSomeSumUsingThenWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :first_sum, result: { sum: 3 } },
          accessible_attributes: [:a, :b, :valid]
        },
        {
          use_case: { class: DoSomeSumUsingThenWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :second_sum, result: { sum: 6 } },
          accessible_attributes: [:a, :b, :valid, :sum]
        },
        {
          use_case: { class: SumHalf, attributes: { sum: 6 } },
          success: { type: :third_sum, result: { sum: 6.5 } },
          accessible_attributes: [:a, :b, :valid, :sum]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, resulta.transitions[index])
      end
    else
      assert_equal([], resulta.transitions)
    end

    # ---

    resultb = DoSomeSumUsingThenWithLambdas.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: DoSomeSumUsingThenWithLambdas, attributes: { a: 1, b: '2' } },
          failure: { type: :error, result: { error: true } },
          accessible_attributes: [:a, :b]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, resultb.transitions[index])
      end
    else
      assert_equal([], resultb.transitions)
    end
  end

  class MultiplyByTwoUsingThenWithLambdas < Micro::Case
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
    ) { MultiplyByTwoUsingThenWithLambdas.call(number: 2) }
  end

  class DoSomeSumUsingPipeWithLambdas < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes \
        | -> { sum_a_and_b } \
        | -> data { add(data, number: 4) } \
        | SumHalf
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
    resulta = DoSomeSumUsingPipeWithLambdas.call(a: 1, b: 2)

    assert_success_result(resulta, value: { sum: 7.5 })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: DoSomeSumUsingPipeWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :valid, result: { valid: true } },
          accessible_attributes: [:a, :b]
        },
        {
          use_case: { class: DoSomeSumUsingPipeWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :first_sum, result: { sum: 3 } },
          accessible_attributes: [:a, :b, :valid]
        },
        {
          use_case: { class: DoSomeSumUsingPipeWithLambdas, attributes: { a: 1, b: 2 } },
          success: { type: :second_sum, result: { sum: 7 } },
          accessible_attributes: [:a, :b, :valid, :sum]
        },
        {
          use_case: { class: SumHalf, attributes: { sum: 7 } },
          success: { type: :third_sum, result: { sum: 7.5 } },
          accessible_attributes: [:a, :b, :valid, :sum]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, resulta.transitions[index])
      end
    else
      assert_equal([], resulta.transitions)
    end

    # ---

    resultb = DoSomeSumUsingPipeWithLambdas.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: { class: DoSomeSumUsingPipeWithLambdas, attributes: { a: 1, b: '2' } },
          failure: { type: :error, result: { error: true } },
          accessible_attributes: [:a, :b]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, resultb.transitions[index])
      end
    else
      assert_equal([], resultb.transitions)
    end
  end

  class MultiplyByTwoUsingPipeWithLambdas < Micro::Case
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
    ) { MultiplyByTwoUsingPipeWithLambdas.call(number: 2) }
  end

  class DoSomeCalcUsingThenWithLambdas < Micro::Case
    attributes :a, :b

    def call!
      get_c
        .then(-> { get_d })
        .then(-> data { sum_a_b_c_d(data) })
        .then(SumHalf)
    end

    private

    def get_c
      Success :c, result: { c: 3 }
    end

    def get_d
      Success :d, result: { d: 4 }
    end

    def sum_a_b_c_d(data)
      c, d = data.fetch(:c), data.fetch(:d)

      Success :sum_a_b_c_d, result: { sum: a + b + c + d }
    end
  end

  def test_the_data_accumulation_through_the_then_method
    result = DoSomeCalcUsingThenWithLambdas.call(a: 1, b: 2)

    assert_success_result(result, value: { sum: 10.5 })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: {
            class: DoSomeCalcUsingThenWithLambdas, attributes: { a: 1, b: 2 }
          },
          success: {type: :c, result: { c: 3 }},
          accessible_attributes: [:a, :b]
        },
        {
          use_case: {
            class: DoSomeCalcUsingThenWithLambdas, attributes: { a: 1, b: 2 }
          },
          success: { type: :d, result: { d: 4 }},
          accessible_attributes: [:a, :b, :c]
        },
        {
          use_case: {
            class: DoSomeCalcUsingThenWithLambdas, attributes: { a: 1, b: 2}
          },
          success: { type: :sum_a_b_c_d, result: { sum: 10 }},
          accessible_attributes: [:a, :b, :c, :d]
        },
        {
          use_case: {
            class: SumHalf, attributes: { sum: 10 }
          },
          success: { type: :third_sum, result: { sum: 10.5 }},
          accessible_attributes: [:a, :b, :c, :d, :sum]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, result.transitions[index])
      end
    else
      assert_equal([], result.transitions)
    end
  end

  class DoSomeCalcUsingPipeWithLambdas < Micro::Case
    attributes :a, :b

    def call!
      get_c \
        |-> { get_d } \
        |-> data { sum_a_b_c_d(data) } \
        | SumHalf
    end

    private

    def get_c
      Success :c, result: { c: 3 }
    end

    def get_d
      Success :d, result: { d: 4 }
    end

    def sum_a_b_c_d(data)
      c, d = data.fetch(:c), data.fetch(:d)

      Success :sum_a_b_c_d, result: { sum: a + b + c + d }
    end
  end

  def test_the_data_accumulation_through_the_pipe_method
    result = DoSomeCalcUsingPipeWithLambdas.call(a: 2, b: 2)

    assert_success_result(result, value: { sum: 11.5 })

    if ::Micro::Case::Result.transitions_enabled?
      [
        {
          use_case: {
            class: DoSomeCalcUsingPipeWithLambdas, attributes: { a: 2, b: 2 }
          },
          success: {type: :c, result: { c: 3 }},
          accessible_attributes: [:a, :b]
        },
        {
          use_case: {
            class: DoSomeCalcUsingPipeWithLambdas, attributes: { a: 2, b: 2 }
          },
          success: { type: :d, result: { d: 4 }},
          accessible_attributes: [:a, :b, :c]
        },
        {
          use_case: {
            class: DoSomeCalcUsingPipeWithLambdas, attributes: { a: 2, b: 2}
          },
          success: { type: :sum_a_b_c_d, result: { sum: 11 }},
          accessible_attributes: [:a, :b, :c, :d]
        },
        {
          use_case: {
            class: SumHalf, attributes: { sum: 11 }
          },
          success: { type: :third_sum, result: { sum: 11.5 }},
          accessible_attributes: [:a, :b, :c, :d, :sum]
        }
      ].each_with_index do |transition, index|
        assert_equal(transition, result.transitions[index])
      end
    else
      assert_equal([], result.transitions)
    end
  end
end
