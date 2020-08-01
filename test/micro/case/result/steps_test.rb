require 'test_helper'

class Micro::Case::Result::StepsTest < Minitest::Test
  class ThirdSum < Micro::Case
    attribute :second_sum

    def call!
      Success result: { third_sum: second_sum + 0.5 }
    end
  end

  class DoSomeSumUsingThen1 < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes
        .then(-> { sum_a_and_b })
        .then(-> data { add(data, number: 3) })
        .then(ThirdSum)
    end

    private

      def validate_attributes
        Kind.of?(Numeric, a, b) ? Success() : Failure()
      end

      def sum_a_and_b
        Success result: { first_sum: a + b }
      end

      def add(data, number:)
        Success result: { second_sum: data[:first_sum] + number }
      end
  end

  def test_the_then_method_with_lambdas
    resulta = DoSomeSumUsingThen1.call(a: 1, b: 2)

    assert_success_result(resulta, value: { third_sum: 6.5 })

    resultb = DoSomeSumUsingThen1.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })
  end

  class DoSomeSumUsingPipe1 < Micro::Case
    attributes :a, :b

    def call!
      validate_attributes \
        | -> { sum_a_and_b } \
        | -> data { add(data, number: 4) } \
        | ThirdSum
    end

    private

      def validate_attributes
        Kind.of?(Numeric, a, b) ? Success() : Failure()
      end

      def sum_a_and_b
        Success result: { first_sum: a + b }
      end

      def add(data, number:)
        Success result: { second_sum: data[:first_sum] + number }
      end
  end

  def test_the_then_method_with_lambdas
    resulta = DoSomeSumUsingPipe1.call(a: 1, b: 2)

    assert_success_result(resulta, value: { third_sum: 7.5 })

    resultb = DoSomeSumUsingPipe1.call(a: 1, b: '2')

    assert_failure_result(resultb, value: { error: true })
  end
end
