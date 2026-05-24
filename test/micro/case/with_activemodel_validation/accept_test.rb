require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '7') <= '6.1.0'

  module Micro::Case::WithActivemodelValidation
    class AcceptTest < Minitest::Test
      class CreateUser < Micro::Case
        attribute :first_name, accept: String,
                               validates: { length: { maximum: 30 } }
        attribute :age,        accept: Integer, allow_nil: true

        def call!
          Success(result: { name: first_name, age: age })
        end
      end

      def test_success_when_accept_passes_and_activemodel_validation_passes
        result = CreateUser.call(first_name: 'Bob')

        assert_success_result(result, value: { name: 'Bob', age: nil })
      end

      def test_failure_when_attribute_is_rejected_by_accept_skips_activemodel_validation
        result = CreateUser.call(first_name: 42, age: 30)

        assert_failure_result(result, type: :invalid_attributes)
        assert_equal({ 'first_name' => 'expected to be a kind of String' }, result.value[:errors])
      end

      def test_failure_when_activemodel_validation_fails_after_accept_passes
        result = CreateUser.call(first_name: 'a' * 50)

        assert_failure_result(result, type: :invalid_attributes)
        # ActiveModel::Errors is returned to preserve the original API
        assert_equal(['is too long (maximum is 30 characters)'], result.value[:errors][:first_name])
      end
    end
  end

end
