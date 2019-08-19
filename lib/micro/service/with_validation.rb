# frozen_string_literal: true

require 'micro/service'

module Micro
  module Service
    class Base
      include Micro::Attributes::Features::ActiveModelValidations

      def call
        return Failure(:validation_error) { {errors: self.errors, service: self} } unless valid?

        __call
      end
    end
  end
end
