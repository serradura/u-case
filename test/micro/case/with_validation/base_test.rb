require 'test_helper'

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') <= '6.0.0'
  require 'u-case/with_validation'

  module Micro::Case
    module WithValidation
      class BaseTest < Minitest::Test
        class Multiply < Micro::Case::Base
          attribute :a
          attribute :b
          validates :a, :b, presence: true, numericality: true

          def call!
            Success(number: a * b)
          end
        end

        class NumberToString < Micro::Case::Base
          attribute :number
          validates :number, presence: true, numericality: true

          def call!
            Success(number.to_s)
          end
        end

        def test_success
          calculation = Multiply.new(a: 2, b: 2).call

          assert(calculation.success?)
          assert_equal(4, calculation.value[:number])
          assert_instance_of(Micro::Case::Result, calculation)

          # ---

          flow= Micro::Case::Flow[Multiply, NumberToString]

          assert_equal('4', flow.call(a: 2, b: 2).value)
        end

        def test_failure
          result = Multiply.new(a: 1, b: nil).call

          assert(result.failure?)
          assert_equal(["can't be blank", 'is not a number'], result.value[:b])
          assert_instance_of(Micro::Case::Result, result)

          counter_1 = 0
          result
            .on_failure(:validation_error) { |errors, use_case| refute(errors.empty?) }
            .on_failure(:validation_error) { |errors, use_case| assert_instance_of(Multiply, use_case) }
            .on_failure(:validation_error) { counter_1 += 1 }
            .on_failure { counter_1 += 1 }

          assert_equal(2, counter_1)

          # ---

          result = Multiply.new(a: 1, b: 'a').call

          assert(result.failure?)
          assert_equal(['is not a number'], result.value[:b])
          assert_instance_of(Micro::Case::Result, result)

          counter_2 = 0
          result
            .on_failure(:validation_error) { |value, use_case| refute(value.empty?) }
            .on_failure(:validation_error) { |value, use_case| assert_instance_of(Multiply, use_case) }
            .on_failure(:validation_error) { counter_2 += 1 }
            .on_failure { counter_2 += 1 }

          assert_equal(2, counter_2)
        end
      end
    end
  end
end