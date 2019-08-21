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
end
