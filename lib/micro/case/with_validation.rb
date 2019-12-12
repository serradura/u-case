# frozen_string_literal: true

require 'micro/case'

module Micro
  class Case
    include Micro::Attributes::Features::ActiveModelValidations

    def self.auto_validation_disabled?
      @disable_auto_validation
    end

    def self.disable_auto_validation
      @disable_auto_validation = true
    end

    def initialize(input)
      __setup_use_case(input)

      run_validations! if respond_to?(:run_validations!, true)
    end

    private

      def __call
        return __call_use_case_flow if __call_use_case_flow?

        return failure_by_validation_error(self) if !self.class.auto_validation_disabled? && invalid?

        __call_use_case
      end

      def failure_by_validation_error(object)
        errors = object.respond_to?(:errors) ? object.errors : object

        Failure(:validation_error) { { errors: errors } }
      end
  end
end
