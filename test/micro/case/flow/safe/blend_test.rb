require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::Flow::Safe::BlendTest < Minitest::Test
  Add2ToAllNumbers = Steps::ConvertToNumbers & Steps::Add2

  DoubleAllNumbers = Micro::Case::Flow::Safe[
    Steps::ConvertToNumbers,
    Steps::Double
  ]

  class SquareAllNumbers
    include Micro::Case::Flow::Safe

    flow Steps::ConvertToNumbers, Steps::Square
  end

  DoubleAllNumbersAndAdd2 = DoubleAllNumbers & Steps::Add2

  SquareAllNumbersAndAdd2 = Micro::Case::Flow::Safe[
    SquareAllNumbers, Steps::Add2
  ]

  SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 & DoubleAllNumbers

  class DoubleAllNumbersAndSquareAndAdd2
    include Micro::Case::Flow::Safe

    flow DoubleAllNumbers, SquareAllNumbersAndAdd2
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

      assert(result.success?)
      assert_instance_of(Micro::Case::Result, result)
      result
        .on_success { |value| assert_equal(example.result, value[:numbers]) }
    end
  end

  def test_result_must_be_a_failure
    EXAMPLES.map(&:flow).each do |flow|
      result = flow.call(numbers: %w[1 1 2 a 3 4])

      assert(result.failure?)
      assert_instance_of(Micro::Case::Result, result)
      result.on_failure { |value| assert_equal('numbers must contain only numeric types', value) }
    end
  end

  class DivideNumbersByZero < Micro::Case::Strict
    attributes :numbers

    def call!
      Success(numbers: numbers.map { |number| number / 0 })
    end
  end

  Add2ToAllNumbersAndDivideByZero = Add2ToAllNumbers & DivideNumbersByZero

  DoubleAllNumbersAndDivideByZero = Micro::Case::Flow::Safe[
    DoubleAllNumbers,
    DivideNumbersByZero
  ]

  class SquareAllNumbersAndDivideByZero
    include Micro::Case::Flow::Safe

    flow SquareAllNumbers, DivideNumbersByZero
  end

  def test_the_expection_interception
    [
      Add2ToAllNumbersAndDivideByZero.call(numbers: %w[4 6 8]),
      DoubleAllNumbersAndDivideByZero.call(numbers: %w[6 4 8]),
      SquareAllNumbersAndDivideByZero.call(numbers: %w[8 4 6])
    ].each do |result|
      assert(result.failure?)
      assert_instance_of(ZeroDivisionError, result.value)
      assert_mc_result(result)

      counter = 0

      result
        .on_failure { counter += 1 }
        .on_failure(:exception) { |value| counter += 1 if value.is_a?(ZeroDivisionError) }
        .on_failure(:exception) { |_value, use_case| counter += 1 if use_case.is_a?(DivideNumbersByZero) }

      assert_equal(3, counter)
    end
  end

  class EmptyHash < Micro::Case::Base
    def call!; Success({}); end
  end

  class Add < Micro::Case::Strict
    attributes :a, :b
    def call!; Success(a + b); end
  end

  def test_that_raises_wrong_usage_exceptions
    flow_1 = EmptyHash & DivideNumbersByZero

    err1 = assert_raises(ArgumentError) { flow_1.call({}) }
    assert_equal('missing keyword: :numbers', err1.message)

    flow_2 = EmptyHash & Add

    err2 = assert_raises(ArgumentError) { flow_2.call({}) }
    assert_equal('missing keywords: :a, :b', err2.message)
  end
end
