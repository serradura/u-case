require 'test_helper'

if ENV.fetch('ACTIVEMODEL_VERSION', '6.1') <= '6.0.0'
  require 'u-case/with_validation'

  module Micro::Case::WithValidation
    class StrictTest < Minitest::Test
      class Multiply < Micro::Case::Strict
        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success(number: a * b)
        end
      end

      class NumberToString < Micro::Case::Strict
        attribute :number
        validates :number, presence: true, numericality: true

        def call!
          Success(number.to_s)
        end
      end

      def test_success
        calculation = Multiply.new(a: 2, b: 2).call

        assert_result_success(calculation, value: { number: 4 })

        # ---

        flow = Micro::Case::Flow([Multiply, NumberToString])

        assert_result_success(flow.call(a: 2, b: 2), value: '4')
      end

      def test_failure
        assert_raises_with_message(ArgumentError, 'missing keywords: :a, :b') { Multiply.call({}) }

        assert_raises_with_message(ArgumentError, 'missing keyword: :b') { Multiply.call({a: 1}) }

        # ---

        result = Multiply.new(a: 1, b: nil).call

        assert_result_failure(result, type: :validation_error)
        assert_equal(["can't be blank", 'is not a number'], result.value[:errors][:b])

        # ---

        result = Multiply.new(a: 1, b: 'a').call

        assert_result_failure(result, type: :validation_error)
        assert_equal(['is not a number'], result.value[:errors][:b])
      end
    end
  end

end
