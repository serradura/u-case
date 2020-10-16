require 'test_helper'

module Micro::Case::WithValidation
  class ConfigTest < Minitest::Test
    i_suck_and_my_tests_are_order_dependent!

    def test_the_default_activemodel_validation_errors_failure_value
      assert_raises_with_message(
        Kind::Error,
        '"validation_error" expected to be a kind of Symbol'
      ) do
        Micro::Case.config do |config|
          config.set_activemodel_validation_errors_failure = 'validation_error'
        end
      end

      # --

      assert_equal(
        :invalid_attributes,
        Micro::Case::Config.instance.activemodel_validation_errors_failure
      )
    end

    if ENV.fetch('ACTIVERECORD_VERSION', '6.1') <= '6.0.0'
      class Multiply < Micro::Case
        attribute :a
        attribute :b
        validates :a, :b, presence: true, numericality: true

        def call!
          Success(result: {number: a * b})
        end
      end

      def test_the_activemodel_validation_errors_failure_config
        Micro::Case.config do |config|
          config.set_activemodel_validation_errors_failure = :validation_error
        end

        assert_failure_result(Multiply.call(a: 2, b: 'a'), type: :validation_error)

        Micro::Case.config do |config|
          config.set_activemodel_validation_errors_failure = :invalid_attributes
        end
      end
    end
  end
end
