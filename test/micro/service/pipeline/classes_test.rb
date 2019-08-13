require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Service::Pipeline::ClassesTest < Minitest::Test
  class Add2ToAllNumbers
    include Micro::Service::Pipeline

    pipeline Steps::ConvertToNumbers, Steps::Add2
  end

  class DoubleAllNumbers
    include Micro::Service::Pipeline

    pipeline Steps::ConvertToNumbers, Steps::Double
  end

  class SquareAllNumbers
    include Micro::Service::Pipeline

    pipeline Steps::ConvertToNumbers, Steps::Square
  end

  class DoubleAllNumbersAndAdd2
    include Micro::Service::Pipeline

    pipeline DoubleAllNumbers, Steps::Add2
  end

  class SquareAllNumbersAndAdd2
    include Micro::Service::Pipeline

    pipeline SquareAllNumbers, Steps::Add2
  end

  class DoubleAllNumbersAndSquareThem
    include Micro::Service::Pipeline

    pipeline DoubleAllNumbers, SquareAllNumbersAndAdd2
  end

  class SquareAllNumbersAndDoubleThem
    include Micro::Service::Pipeline

    pipeline SquareAllNumbersAndAdd2, DoubleAllNumbers
  end

  EXAMPLES = [
    { pipeline: Add2ToAllNumbers, result: [3, 3, 4, 4, 5, 6] },
    { pipeline: DoubleAllNumbers, result: [2, 2, 4, 4, 6, 8] },
    { pipeline: SquareAllNumbers, result: [1, 1, 4, 4, 9, 16] },
    { pipeline: DoubleAllNumbersAndAdd2, result: [4, 4, 6, 6, 8, 10] },
    { pipeline: SquareAllNumbersAndAdd2, result: [3, 3, 6, 6, 11, 18] },
    { pipeline: DoubleAllNumbersAndSquareThem, result: [6, 6, 18, 18, 38, 66] },
    { pipeline: SquareAllNumbersAndDoubleThem, result: [6, 6, 12, 12, 22, 36] }
  ].map(&OpenStruct.method(:new))

  def test_the_data_validation_error_when_calling_with_the_wrong_king_of_data
    [nil, 1, true, '', []].each do |arg|
      EXAMPLES.map(&:pipeline).each do |pipeline|
        err1 = assert_raises(ArgumentError) { pipeline.call(arg) }
        assert_equal('argument must be a Hash', err1.message)

        err2 = assert_raises(ArgumentError) { pipeline.new(arg).call }
        assert_equal('argument must be a Hash', err2.message)
      end
    end
  end

  def test_result_must_be_success
    EXAMPLES.each do |example|
      result = example.pipeline.call(numbers: %w[1 1 2 2 3 4])

      assert(result.success?)
      assert_instance_of(Micro::Service::Result::Success, result)
      result
        .on_success { |value| assert_equal(example.result, value[:numbers]) }
    end
  end

  def test_result_must_be_a_failure
    EXAMPLES.map(&:pipeline).each do |pipeline|
      result = pipeline.call(numbers: %w[1 1 2 a 3 4])

      assert(result.failure?)
      assert_instance_of(Micro::Service::Result::Failure, result)
      result.on_failure { |value| assert_equal('numbers must contain only numeric types', value) }
    end
  end

  class Foo
    include Micro::Service::Pipeline
  end

  def test_the_error_when_using_a_pipeline_class_without_a_defined_set_of_services
    err1 = assert_raises(ArgumentError) { Foo.new({}) }
    assert_equal("This class hasn't declared its pipeline. Please, use the `pipeline()` macro to define one.", err1.message)

    err2 = assert_raises(ArgumentError) { Foo.call({}) }
    assert_equal("This class hasn't declared its pipeline. Please, use the `pipeline()` macro to define one.", err2.message)
  end
end
