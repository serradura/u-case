require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.1') <= '6.0.0'

  module Micro::Case::WithActivemodelValidation
    class DisableAutoValidationTest < Minitest::Test
      class Multiply < Micro::Case
        disable_auto_validation

        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success result: { number: a * b }
        end
      end

      class Add < Micro::Case
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

        assert_raises_with_message(TypeError, /String can't be coerced into (Integer|Fixnum)/) do
          Multiply.call(a: 2, b: 'a')
        end
      end
    end
  end

end
