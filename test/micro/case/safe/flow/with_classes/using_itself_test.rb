require 'test_helper'

module Micro::Case::Safe::Flow::WithClasses
  class UsingItselfTest < Minitest::Test
    class ConvertTextToNumber < Micro::Case::Safe
      attribute :text

      def call!
        Success { { number: text.to_i } }
      end
    end

    class ConvertNumberToText < Micro::Case::Safe
      attribute :number

      def call!
        Success { { text: number.to_s } }
      end
    end

    class Double < Micro::Case::Safe
      attribute :number

      def call!
        Success { { number: number * 2 } }
      end

      flow ConvertTextToNumber,
           self.call!,
           ConvertNumberToText
    end

    def test_the_use_case_result
      result = Double.call(text: '4')

      assert_success_result(result, value: { text: '8' })

      assert_equal(
        [ConvertTextToNumber, Double::Flow_Step, ConvertNumberToText],
        Double.use_cases
      )

      # ---

      instance = Double.new(text: '5')

      assert_success_result(instance.call, value: { text: '10' })

      assert_equal(
        [ConvertTextToNumber, Double::Flow_Step, ConvertNumberToText],
        instance.use_cases
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
end
