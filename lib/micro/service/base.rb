# frozen_string_literal: true

module Micro
  module Service
    class Base
      include Micro::Attributes.without(:strict_initialize)

      INVALID_RESULT = '#call! must return a Micro::Service::Result instance'.freeze

      ResultIsAlreadyDefined = ArgumentError.new('result is already defined'.freeze)

      private_constant :INVALID_RESULT, :ResultIsAlreadyDefined

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
        result = call!
        return result if result.is_a?(Service::Result)
        raise TypeError, self.class.name + INVALID_RESULT
      end

      def __set_result__(result)
        raise ResultIsAlreadyDefined if @__result
        @__result = result
      end

      private

        def __get_result__
          @__result ||= Result.new
        end

        def Success(arg=nil)
          value, type = block_given? ? [yield, arg] : [arg, nil]
          __get_result__.__set__(true, value, type)
        end

        def Failure(arg=nil)
          value, type = block_given? ? [yield, arg] : [arg, nil]
          __get_result__.__set__(false, value, type)
        end
    end
  end
end
