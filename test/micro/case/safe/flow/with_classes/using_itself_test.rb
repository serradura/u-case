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
  end
end
