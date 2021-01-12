require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.2') <= '6.1.0'

  module Micro::Case::WithActivemodelValidation::Safe
    class DisableAutoValidationTest < Minitest::Test
      class Multiply < Micro::Case::Safe
        disable_auto_validation

        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success(result: { number: a * b })
        end
      end

      class Add < Micro::Case::Safe
        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success result: { number: a + b }
        end
      end

      def test_the_disable_auto_validation_macro
        result1 = Add.call(a: 'a', b: 2)

        assert_failure_result(result1, type: :invalid_attributes)

        # ---

        result2 = Multiply.call(a: 2, b: 'a')

        assert_exception_result(result2, value: { exception: TypeError })
      end
    end
  end

end
