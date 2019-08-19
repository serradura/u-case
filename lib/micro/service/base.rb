# frozen_string_literal: true

module Micro
  module Service
    class Base
      include Micro::Attributes.without(:strict_initialize)

      UNEXPECTED_RESULT = '#call! must return a Micro::Service::Result instance'.freeze
      InvalidResultInstance = ArgumentError.new('argument must be an instance of Micro::Service::Result'.freeze)
      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      private_constant :UNEXPECTED_RESULT, :ResultIsAlreadyDefined, :InvalidResultInstance

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
          raise TypeError, self.class.name + UNEXPECTED_RESULT
        end

        def __get_result__
          @__result ||= Result.new
        end

        def Success(arg = :ok)
          block_given? ? (value, type = yield, arg) : (value, type = arg, :ok)
          __get_result__.__set__(true, value, type)
        end

        def Failure(arg = :error)
          block_given? ? (value, type = yield, arg) : (value, type = arg, :error)
          __get_result__.__set__(false, value, type)
        end
    end
  end
end
