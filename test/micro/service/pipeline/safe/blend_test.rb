require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Service::Pipeline::Safe::BlendTest < Minitest::Test
  Add2ToAllNumbers = Steps::ConvertToNumbers & Steps::Add2

  DoubleAllNumbers = Micro::Service::Pipeline::Safe[
    Steps::ConvertToNumbers,
    Steps::Double
  ]

  class SquareAllNumbers
    include Micro::Service::Pipeline::Safe

    pipeline Steps::ConvertToNumbers, Steps::Square
  end

  DoubleAllNumbersAndAdd2 = DoubleAllNumbers & Steps::Add2

  SquareAllNumbersAndAdd2 = Micro::Service::Pipeline::Safe[
    SquareAllNumbers, Steps::Add2
  ]

  SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 & DoubleAllNumbers

  class DoubleAllNumbersAndSquareAndAdd2
    include Micro::Service::Pipeline::Safe

    pipeline DoubleAllNumbers, SquareAllNumbersAndAdd2
  end

  EXAMPLES = [
    { pipeline: Add2ToAllNumbers, result: [3, 3, 4, 4, 5, 6] },
    { pipeline: DoubleAllNumbers, result: [2, 2, 4, 4, 6, 8] },
    { pipeline: SquareAllNumbers, result: [1, 1, 4, 4, 9, 16] },
    { pipeline: DoubleAllNumbersAndAdd2, result: [4, 4, 6, 6, 8, 10] },
    { pipeline: SquareAllNumbersAndAdd2, result: [3, 3, 6, 6, 11, 18] },
    { pipeline: SquareAllNumbersAndDouble, result: [6, 6, 12, 12, 22, 36] },
    { pipeline: DoubleAllNumbersAndSquareAndAdd2, result: [6, 6, 18, 18, 38, 66] }
  ].map(&OpenStruct.method(:new))

  def test_result_must_be_success
    EXAMPLES.each do |example|
      result = example.pipeline.call(numbers: %w[1 1 2 2 3 4])

      assert(result.success?)
      assert_instance_of(Micro::Service::Result, result)
      result
        .on_success { |value| assert_equal(example.result, value[:numbers]) }
    end
  end

  def test_result_must_be_a_failure
    EXAMPLES.map(&:pipeline).each do |pipeline|
      result = pipeline.call(numbers: %w[1 1 2 a 3 4])

      assert(result.failure?)
      assert_instance_of(Micro::Service::Result, result)
      result.on_failure { |value| assert_equal('numbers must contain only numeric types', value) }
    end
  end

  class DivideNumbersByZero < Micro::Service::Strict
    attributes :numbers

    def call!
      Success(numbers: numbers.map { |number| number / 0 })
    end
  end

  Add2ToAllNumbersAndDivideByZero = Add2ToAllNumbers & DivideNumbersByZero

  DoubleAllNumbersAndDivideByZero = Micro::Service::Pipeline::Safe[
    DoubleAllNumbers,
    DivideNumbersByZero
  ]

  class SquareAllNumbersAndDivideByZero
    include Micro::Service::Pipeline::Safe

    pipeline SquareAllNumbers, DivideNumbersByZero
  end

  def test_the_expection_interception
    [
      Add2ToAllNumbersAndDivideByZero.call(numbers: %w[4 6 8]),
      DoubleAllNumbersAndDivideByZero.call(numbers: %w[6 4 8]),
      SquareAllNumbersAndDivideByZero.call(numbers: %w[8 4 6])
    ].each do |result|
      assert(result.failure?)
      assert_instance_of(ZeroDivisionError, result.value)
      assert_kind_of(Micro::Service::Result, result)

      counter = 0

      result
        .on_failure { counter += 1 }
        .on_failure(:exception) { |value| counter += 1 if value.is_a?(ZeroDivisionError) }
        .on_failure(:exception) { |_value, service| counter += 1 if service == DivideNumbersByZero}

      assert_equal(3, counter)
    end
  end

  class EmptyHash < Micro::Service::Base
    def call!; Success({}); end
  end

  class Add < Micro::Service::Strict
    attributes :a, :b
    def call!; Success(a + b); end
  end

  def test_that_raises_wrong_usage_exceptions
    pipeline_1 = EmptyHash & DivideNumbersByZero

    err1 = assert_raises(ArgumentError) { pipeline_1.call({}) }
    assert_equal('missing keyword: :numbers', err1.message)

    pipeline_2 = EmptyHash & Add

    err2 = assert_raises(ArgumentError) { pipeline_2.call({}) }
    assert_equal('missing keywords: :a, :b', err2.message)
  end
end
