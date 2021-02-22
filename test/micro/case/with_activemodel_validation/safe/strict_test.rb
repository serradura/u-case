require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '7') <= '6.1.0'

  module Micro::Case::WithActivemodelValidation::Safe
    class StrictTest < Minitest::Test
      class Multiply < Micro::Case::Strict::Safe
        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success result: { number: a * b }
        end
      end

      class NumberToString < Micro::Case::Strict::Safe
        attribute :number
        validates :number, presence: true, numericality: true

        def call!
          Success result: { string: number.to_s }
        end
      end

      def test_success
        calculation = Multiply.call(a: 2, b: 2)

        assert_success_result(calculation, value: { number: 4 })

        # ---

        flow = Micro::Cases.flow([Multiply, NumberToString])

        assert_success_result(flow.call(a: 2, b: 2), value: { string: '4' } )
      end

      def test_failure
        assert_raises_with_message(ArgumentError, 'missing keywords: :a, :b') { Multiply.call({}) }

        assert_raises_with_message(ArgumentError, 'missing keyword: :b') { Multiply.call({a: 1}) }

        # ---

        result = Multiply.call(a: 1, b: nil)

        assert_failure_result(result, type: :invalid_attributes)
        assert_equal(["can't be blank", 'is not a number'], result.value[:errors][:b])

        # ---

        result = Multiply.call(a: 1, b: 'a')

        assert_failure_result(result, type: :invalid_attributes)
        assert_equal(['is not a number'], result.value[:errors][:b])
      end
    end
  end

end
