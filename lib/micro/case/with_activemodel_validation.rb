# frozen_string_literal: true

require 'kind/active_model/validation'

require 'micro/case'

module Micro
  class Case
    include Micro::Attributes::Features::ActiveModelValidations

    def self.auto_validation_disabled?
      return @disable_auto_validation if defined?(@disable_auto_validation)
    end

    def self.disable_auto_validation
      @disable_auto_validation = true
    end

    def initialize(input)
      __setup_use_case(input)

      run_validations! if respond_to?(:run_validations!, true)
    end

    private

      def __call_use_case
        return failure_by_validation_error(self) if !self.class.auto_validation_disabled? && invalid?

        result = call!

        return result if result.is_a?(Result)

        raise Error::UnexpectedResult.new("#{self.class.name}#call!")
      end

      def failure_by_validation_error(object)
        errors = object.respond_to?(:errors) ? object.errors : object

        Failure :validation_error, result: { errors: errors }
      end
  end
end
