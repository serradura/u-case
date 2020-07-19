require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Cases::Safe::Flow::BlendTest < Minitest::Test
  Add2ToAllNumbers = Micro::Cases.safe_flow([
    Steps::ConvertToNumbers, Steps::Add2
  ])

  DoubleAllNumbers = Micro::Cases.safe_flow([
    Steps::ConvertToNumbers,
    Steps::Double
  ])

  class SquareAllNumbers < Micro::Case::Safe
    flow Steps::ConvertToNumbers,
        Steps::Square
  end

  DoubleAllNumbersAndAdd2 = Micro::Cases.safe_flow([
    DoubleAllNumbers, Steps::Add2
  ])

  SquareAllNumbersAndAdd2 = Micro::Cases.safe_flow([
    SquareAllNumbers, Steps::Add2
  ])

  SquareAllNumbersAndDouble = Micro::Cases.safe_flow([
    SquareAllNumbersAndAdd2, DoubleAllNumbers
  ])

  class DoubleAllNumbersAndSquareAndAdd2 < Micro::Case::Safe
    flow DoubleAllNumbers,
        SquareAllNumbersAndAdd2
  end

  EXAMPLES = [
    { flow: Add2ToAllNumbers, result: [3, 3, 4, 4, 5, 6] },
    { flow: DoubleAllNumbers, result: [2, 2, 4, 4, 6, 8] },
    { flow: SquareAllNumbers, result: [1, 1, 4, 4, 9, 16] },
    { flow: DoubleAllNumbersAndAdd2, result: [4, 4, 6, 6, 8, 10] },
    { flow: SquareAllNumbersAndAdd2, result: [3, 3, 6, 6, 11, 18] },
    { flow: SquareAllNumbersAndDouble, result: [6, 6, 12, 12, 22, 36] },
    { flow: DoubleAllNumbersAndSquareAndAdd2, result: [6, 6, 18, 18, 38, 66] }
  ].map(&OpenStruct.method(:new))

  def test_result_must_be_success
    EXAMPLES.each do |example|
      result = example.flow.call(numbers: %w[1 1 2 2 3 4])

      assert_success_result(result, value: { numbers: example.result })
    end
  end

  def test_result_must_be_a_failure
    EXAMPLES.map(&:flow).each do |flow|
      result = flow.call(numbers: %w[1 1 2 a 3 4])

      assert_failure_result(result, value: 'numbers must contain only numeric types')
    end
  end

  class DivideNumbersByZero < Micro::Case::Strict
    attributes :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number / 0 } }
    end
  end

  class Add2ToAllNumbersAndDivideByZero < Micro::Case::Safe
    flow Add2ToAllNumbers,
      DivideNumbersByZero
  end

  DoubleAllNumbersAndDivideByZero = Micro::Cases.safe_flow([
    DoubleAllNumbers,
    DivideNumbersByZero
  ])

  class SquareAllNumbersAndDivideByZero < Micro::Case::Safe
    flow SquareAllNumbers,
        DivideNumbersByZero
  end

  def test_the_expection_interception
    [
      Add2ToAllNumbersAndDivideByZero.call(numbers: %w[4 6 8]),
      DoubleAllNumbersAndDivideByZero.call(numbers: %w[6 4 8]),
      SquareAllNumbersAndDivideByZero.call(numbers: %w[8 4 6])
    ].each do |result|
      assert_exception_result(result, value: ZeroDivisionError)
    end
  end

  class EmptyHash < Micro::Case
    def call!; Success(result: {}); end
  end

  class Add < Micro::Case::Strict
    attributes :a, :b

    def call!; Success(result: a + b); end
  end

  def test_that_raises_wrong_usage_exceptions
    flow_1 = Micro::Cases.safe_flow([
      EmptyHash, DivideNumbersByZero
    ])

    assert_raises_with_message(ArgumentError, 'missing keyword: :numbers') { flow_1.call({}) }

    flow_2 = Micro::Cases.safe_flow([
      EmptyHash, Add
    ])

    assert_raises_with_message(ArgumentError, 'missing keywords: :a, :b') { flow_2.call({}) }
  end
end
