# frozen_string_literal: true

require 'micro/service'

module Micro
  class Service::WithValidation < Micro::Service::Base
    include Micro::Attributes::Features::ActiveModelValidations

    def call
      return Failure(errors: self.errors) unless valid?

      super
    end
  end

  class Service::Strict::Validation < Service::WithValidation
    include Micro::Attributes::Features::StrictInitialize
  end
end
