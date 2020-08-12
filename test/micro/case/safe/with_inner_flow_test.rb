require 'test_helper'

class Micro::Case::Safe::WithInnerFlowTest < Minitest::Test
  class ConvertTextToNumber < Micro::Case::Safe
    attribute :text

    def call!
      Success result: { number: text.to_i }
    end
  end

  class ConvertNumberToText < Micro::Case::Safe
    attribute :number

    def call!
      Success result: { text: number.to_s }
    end
  end

  class Double < Micro::Case::Safe
    flow ConvertTextToNumber,
        self.call!,
        ConvertNumberToText

    attribute :number

    def call!
      Success result: { number: number * 2 }
    end
  end

  def test_the_use_case_result
    result = Double.call(text: '4')

    assert_success_result(result, value: { text: '8' })

    assert_equal(
      [ConvertTextToNumber, Double::Self, ConvertNumberToText],
      Double.use_cases
    )
  end

  begin
    class DoubleFoo < Double
    end
  rescue RuntimeError => e
    @@__inheritance_violation_message = e.message
  end

  def test_the_inheritance_violation
    expected_message =
      "Wooo, you can't do this! Inherits from a use case which has an inner flow violates "\
      "one of the project principles: Solve complex business logic, by allowing the composition of use cases. "\
      "Instead of doing this, declare a new class/constant with the steps needed.\n\n"\
      "Related issue: https://github.com/serradura/u-case/issues/19\n"

    assert_equal(expected_message, @@__inheritance_violation_message)

    assert_raises_with_message(RuntimeError, expected_message) do
      Class.new(Double)
    end
  end
end
