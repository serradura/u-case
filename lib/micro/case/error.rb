# frozen_string_literal: true

module Micro
  module Case
    module Error
      class UnexpectedResult < TypeError
        MESSAGE = '#call! must return an instance of Micro::Case::Result'.freeze

        def initialize(klass); super(klass.name + MESSAGE); end
      end

      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      InvalidResultType = TypeError.new('type must be a Symbol'.freeze)
      InvalidResultInstance = ArgumentError.new('argument must be an instance of Micro::Case::Result'.freeze)

      InvalidUseCase = TypeError.new('use case must be a kind or an instance of Micro::Case::Base'.freeze)
      InvalidUseCases = ArgumentError.new('argument must be a collection of `Micro::Case::Base` classes'.freeze)

      UndefinedFlow = ArgumentError.new("This class hasn't declared its flow. Please, use the `flow()` macro to define one.".freeze)

      class InvalidAccessToTheUseCaseObject < StandardError
        MSG = 'only a failure result can access its use case object'.freeze

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
