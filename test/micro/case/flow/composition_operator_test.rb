require 'ostruct'
require 'test_helper'
require 'support/steps'

class Micro::Case::Flow::CompositionOperatorTest < Minitest::Test
  Add2ToAllNumbers = Steps::ConvertToNumbers >> Steps::Add2
  DoubleAllNumbers = Steps::ConvertToNumbers >> Steps::Double
  SquareAllNumbers = Steps::ConvertToNumbers >> Steps::Square

  DoubleAllNumbersAndAdd2 = DoubleAllNumbers >> Steps::Add2
  SquareAllNumbersAndAdd2 = SquareAllNumbers >> Steps::Add2

  SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 >> DoubleAllNumbers
  DoubleAllNumbersAndSquareAndAdd2 = DoubleAllNumbers >> SquareAllNumbersAndAdd2

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
        assert_raises_with_message(ArgumentError, 'argument must be a Hash') { flow.call(arg) }
      end
    end
  end

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

  def test_the_error_when_using_the_safe_composition_operator
    double_all_numbers = Steps::ConvertToNumbers >> Steps::Double

    assert_raises_with_message(
      NoMethodError,
      /undefined method `&' for #<Micro::Case::Flow::Reducer.*>. Please, use the method `>>' to avoid this error\./
    ) { double_all_numbers & Steps::Add2 }
  end
end
