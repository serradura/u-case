require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.2') <= '6.1.0'

  module Micro::Case::WithActivemodelValidation
    module ClassesWithFlows
      class FirstStepWithValidationTest < Minitest::Test
        class ConvertTextToNumber < Micro::Case
          attribute :text

          validates :text, presence: true

          def call!
            number = text.include?('.') ? text.to_f : text.to_i
            Success result: { number: number }
          end
        end

        class ConvertNumberToText < Micro::Case
          attribute :number

          def call!
            Success result: { text: number.to_s }
          end
        end

        class Double < Micro::Case
          flow ConvertTextToNumber,
              self.call!,
              ConvertNumberToText

          attribute :number

          validates :number, numericality: { only_integer: true }

          def call!
            Success result: { number: number * 2 }
          end
        end

        def test_the_use_case_result
          assert_failure_result(Double.call(text: ''), type: :invalid_attributes)

          # ---

          result = Double.call(text: '4')

          assert_success_result(result, value: { text: '8' })

          assert_equal(
            [ConvertTextToNumber, Double::Self, ConvertNumberToText],
            Double.use_cases
          )

          # ---

          result = Double.call(text: '4.0')

          assert_failure_result(result, type: :invalid_attributes)

          assert_equal(['must be an integer'], result.value[:errors][:number])
        end
      end
    end
  end

end
