require 'test_helper'

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') <= '6.0.0'
  require 'u-case/with_validation'

  module Micro::Case::WithValidation::Safe
    class DisableAutoValidationTest < Minitest::Test
      class Multiply < Micro::Case::Safe
        disable_auto_validation

        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success(number: a * b)
        end
      end

      class Add < Micro::Case::Safe
        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success(number: a + b)
        end
      end

      def test_the_disable_auto_validation_macro
        result1 = Add.call(a: 'a', b: 2)

        assert_failure_result(result1, type: :validation_error)

        # ---

        result2 = Multiply.call(a: 2, b: 'a')

        assert_exception_result(result2, value: TypeError)
      end
    end
  end

end
