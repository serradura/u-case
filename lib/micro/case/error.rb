# frozen_string_literal: true

module Micro
  class Case
    module Error
      class UnexpectedResult < TypeError
        MESSAGE = '#call! must return an instance of Micro::Case::Result'.freeze

        def initialize(klass); super(klass.name + MESSAGE); end
      end

      class ResultIsAlreadyDefined < ArgumentError
        def initialize; super('result is already defined'.freeze); end
      end

      class InvalidResultType < TypeError
        def initialize; super('type must be a Symbol'.freeze); end
      end

      class InvalidResultData < TypeError
      end

      class InvalidSuccessResult < InvalidResultData
        def initialize(object)
          super("Success(result: #{object.inspect}) must be a Hash or Symbol")
        end
      end

      class InvalidFailureResult < InvalidResultData
        def initialize(object)
          super("Failure(result: #{object.inspect}) must be a Hash, Symbol or an Exception")
        end
      end

      class InvalidResultInstance < ArgumentError
        def initialize; super('argument must be an instance of Micro::Case::Result'.freeze); end
      end

      class InvalidUseCase < TypeError
        def initialize; super('use case must be a kind or an instance of Micro::Case'.freeze); end
      end

      class InvalidInvocationOfTheThenMethod < StandardError
        def initialize; super('Invalid invocation of the Micro::Case::Result#then method'); end
      end

      class InvalidAccessToTheUseCaseObject < StandardError
        def initialize; super('only a failure result can access its use case object'.freeze); end
      end

      def self.by_wrong_usage?(exception)
        exception.is_a?(InvalidResultData) || exception.is_a?(Error::UnexpectedResult) || exception.is_a?(ArgumentError)
      end
    end
  end
end
