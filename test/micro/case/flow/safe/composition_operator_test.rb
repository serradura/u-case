require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::Flow::Safe::CompositionOperatorTest < Minitest::Test
  Add2ToAllNumbers = Steps::ConvertToNumbers & Steps::Add2
  DoubleAllNumbers = Steps::ConvertToNumbers & Steps::Double
  SquareAllNumbers = Steps::ConvertToNumbers & Steps::Square

  DoubleAllNumbersAndAdd2 = DoubleAllNumbers & Steps::Add2
  SquareAllNumbersAndAdd2 = SquareAllNumbers & Steps::Add2

  SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 & DoubleAllNumbers
  DoubleAllNumbersAndSquareAndAdd2 = DoubleAllNumbers & SquareAllNumbersAndAdd2

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
        err = assert_raises(ArgumentError) { flow.call(arg) }
        assert_equal('argument must be a Hash', err.message)
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

  def test_the_error_when_using_the_regular_composition_operator
    double_all_numbers = Steps::ConvertToNumbers & Steps::Double

    err = assert_raises(NoMethodError) { double_all_numbers >> Steps::Add2 }
    assert_match(/undefined method `>>' for #<Micro::Case::Flow::SafeReducer.*>. Please, use the method `&' to avoid this error\./, err.message)
  end
end
