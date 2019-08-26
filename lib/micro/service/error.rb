# frozen_string_literal: true

module Micro
  module Service
    module Error
      class UnexpectedResult < TypeError
        MESSAGE = '#call! must return an instance of Micro::Service::Result'.freeze

        def initialize(klass); super(klass.name + MESSAGE); end
      end

      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      InvalidResultType = TypeError.new('type must be a Symbol'.freeze)
      InvalidResultInstance = ArgumentError.new('argument must be an instance of Micro::Service::Result'.freeze)

      InvalidService = TypeError.new('service must be a kind or an instance of Micro::Service::Base'.freeze)
      InvalidServices = ArgumentError.new('argument must be a collection of `Micro::Service::Base` classes'.freeze)

      UndefinedPipeline = ArgumentError.new("This class hasn't declared its pipeline. Please, use the `pipeline()` macro to define one.".freeze)

      class InvalidAccessToTheServiceObject < StandardError
        MSG = 'only a failure result can access its service object'.freeze

        def initialize(message = MSG); super; end
      end

      module ByWrongUsage
        def self.check(exception)
          exception.is_a?(Error::UnexpectedResult) || exception.is_a?(ArgumentError)
        end
      end
    end
  end
end
