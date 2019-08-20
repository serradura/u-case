# frozen_string_literal: true

module Micro
  module Service
    class Base
      include Micro::Attributes.without(:strict_initialize)

      class UnexpectedResult < TypeError
        MESSAGE = '#call! must return an instance of Micro::Service::Result'.freeze

        def initialize(klass); super(klass.name + MESSAGE); end
      end

      InvalidResultInstance = ArgumentError.new('argument must be an instance of Micro::Service::Result'.freeze)
      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      private_constant :ResultIsAlreadyDefined, :InvalidResultInstance

      def self.>>(service)
        Micro::Service::Pipeline[self, service]
      end

      def self.call(options = {})
        new(options).call
      end

      def self.__new__(result, arg)
        instance = allocate
        instance.__set_result__(result)
        instance.send(:initialize, arg)
        instance
      end

      def call!
        raise NotImplementedError
      end

      def call
        __call
      end

      def __set_result__(result)
        raise InvalidResultInstance unless result.is_a?(Result)
        raise ResultIsAlreadyDefined if @__result
        @__result = result
      end

      private

        def __call
          result = call!
          return result if result.is_a?(Service::Result)
          raise UnexpectedResult.new(self.class)
        end

        def __get_result__
          @__result ||= Result.new
        end

        def Success(arg = :ok)
          value, type = block_given? ? [yield, arg] : [arg, :ok]
          __get_result__.__set__(true, value, type, nil)
        end

        def Failure(arg = :error)
          value, type = block_given? ? [yield, arg] : [arg, :error]
          __get_result__.__set__(false, value, type, self)
        end
    end
  end
end
