require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::Flow::ClassesTest < Minitest::Test
  class Add2ToAllNumbers
    include Micro::Case::Flow

    flow Steps::ConvertToNumbers, Steps::Add2
  end

  class DoubleAllNumbers
    include Micro::Case::Flow

    flow Steps::ConvertToNumbers, Steps::Double
  end

  class SquareAllNumbers
    include Micro::Case::Flow

    flow Steps::ConvertToNumbers, Steps::Square
  end

  class DoubleAllNumbersAndAdd2
    include Micro::Case::Flow

    flow DoubleAllNumbers, Steps::Add2
  end

  class SquareAllNumbersAndAdd2
    include Micro::Case::Flow

    flow SquareAllNumbers, Steps::Add2
  end

  class SquareAllNumbersAndDouble
    include Micro::Case::Flow

    flow SquareAllNumbersAndAdd2, DoubleAllNumbers
  end

  class DoubleAllNumbersAndSquareAndAdd2
    include Micro::Case::Flow

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

  def test_the_data_validation_error_when_calling_with_the_wrong_king_of_data
    [nil, 1, true, '', []].each do |arg|
      EXAMPLES.map(&:flow).each do |flow|
        err1 = assert_raises(ArgumentError) { flow.call(arg) }
        assert_equal('argument must be a Hash', err1.message)

        err2 = assert_raises(ArgumentError) { flow.new(arg).call }
        assert_equal('argument must be a Hash', err2.message)
      end
    end
  end

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

  class Foo
    include Micro::Case::Flow
  end

  def test_the_error_when_using_a_flow_class_without_a_defined_set_of_use_cases
    err1 = assert_raises(ArgumentError) { Foo.new({}) }
    assert_equal("This class hasn't declared its flow. Please, use the `flow()` macro to define one.", err1.message)

    err2 = assert_raises(ArgumentError) { Foo.call({}) }
    assert_equal("This class hasn't declared its flow. Please, use the `flow()` macro to define one.", err2.message)
  end
end
