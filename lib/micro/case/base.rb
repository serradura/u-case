# frozen_string_literal: true

module Micro
  module Case
    class Base
      include Micro::Attributes.without(:strict_initialize)

      def self.to_proc
        Proc.new { |arg| call(arg) }
      end

      def self.>>(use_case)
        Pipeline[self, use_case]
      end

      def self.&(use_case)
        Pipeline::Safe[self, use_case]
      end

      def self.call(options = {})
        new(options).call
      end

      def self.__new__(result, arg)
        instance = new(arg)
        instance.__set_result__(result)
        instance
      end

      def self.__failure_type(arg, type)
        return type if type != :error

        case arg
        when Exception then :exception
        when Symbol then arg
        else type
        end
      end

      def call!
        raise NotImplementedError
      end

      def call
        __call
      end

      def __set_result__(result)
        raise Error::InvalidResultInstance unless result.is_a?(Result)
        raise Error::ResultIsAlreadyDefined if @__result
        @__result = result
      end

      private

        def __call
          result = call!
          return result if result.is_a?(Result)
          raise Error::UnexpectedResult.new(self.class)
        end

        def __get_result__
          @__result ||= Result.new
        end

        def Success(arg = :ok)
          value, type = block_given? ? [yield, arg] : [arg, :ok]
          __get_result__.__set__(true, value, type, nil)
        end

        def Failure(arg = :error)
          value = block_given? ? yield : arg
          type = self.class.__failure_type(value, block_given? ? arg : :error)
          __get_result__.__set__(false, value, type, self)
        end
    end
  end
end
