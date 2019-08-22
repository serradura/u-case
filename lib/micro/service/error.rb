# frozen_string_literal: true

module Micro
  module Service
    module Error
      class UnexpectedResult < TypeError
        MESSAGE = '#call! must return an instance of Micro::Service::Result'.freeze

        def initialize(klass); super(klass.name + MESSAGE); end
      end

      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      InvalidResultInstance = ArgumentError.new('argument must be an instance of Micro::Service::Result'.freeze)

      InvalidServices = ArgumentError.new('argument must be a collection of `Micro::Service::Base` classes'.freeze)

      UndefinedPipeline = ArgumentError.new("This class hasn't declared its pipeline. Please, use the `pipeline()` macro to define one.".freeze)

      module ByWrongUsage
        MISSING_KEYWORD = 'missing keyword'.freeze
        ARGUMENT_MUST_BE_A_HASH = 'argument must be a Hash'.freeze

        def self.check(exception)
          msg = exception.message
          arg_error = msg == ARGUMENT_MUST_BE_A_HASH || msg.include?(MISSING_KEYWORD)
          arg_error || exception.is_a?(Error::UnexpectedResult)
        end
      end
    end
  end
end
