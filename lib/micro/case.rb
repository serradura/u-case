# frozen_string_literal: true

require 'micro/attributes'
# frozen_string_literal: true

module Micro
  class Case
    require 'micro/case/version'
    require 'micro/case/result'
    require 'micro/case/error'
    require 'micro/case/safe'
    require 'micro/case/strict'
    require 'micro/case/flow/reducer'
    require 'micro/case/flow'
    require 'micro/case/safe/flow'

    include Micro::Attributes.without(:strict_initialize)

    def self.to_proc
      Proc.new { |arg| call(arg) }
    end

    def self.Flow(args)
      Flow::Reducer.build(Array(args))
    end

    def self.>>(use_case)
      Flow([self, use_case])
    end

    def self.&(use_case)
      Safe::Flow([self, use_case])
    end

    def self.call(options = {})
      new(options).call
    end

    def self.__new__(result, arg)
      instance = new(arg)
      instance.__set_result__(result)
      instance
    end

    def self.__get_flow__
      @__flow
    end

    private_class_method def self.__set_flow__(reducer, args)
      def self.use_cases; __get_flow__.use_cases; end

      self.class_eval('def use_cases; self.class.use_cases; end')

      reducer.build(args)
    end

    def self.flow(*args)
      @__flow ||= __set_flow__(Flow::Reducer, args)
    end

    def self.call!
      return const_get(:Flow_Step) if const_defined?(:Flow_Step)

      const_set(:Flow_Step, Class.new(self) do
        private def __call
          __call_use_case
        end
      end)
    end

    def initialize(input)
      @__input = input
      self.attributes = input
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
        return self.class.__get_flow__.call(@__input) if self.class.__get_flow__

        __call_use_case
      end

      def __call_use_case
        result = call!

        return result if result.is_a?(Result)

        raise Error::UnexpectedResult.new(self.class)
      end

      def Success(arg = :ok)
        value, type = block_given? ? [yield, arg] : [arg, :ok]

        __get_result__.__set__(true, value, type, nil)
      end

      def Failure(arg = :error)
        value = block_given? ? yield : arg
        type = __map_failure_type(value, block_given? ? arg : :error)

        __get_result__.__set__(false, value, type, self)
      end

      def __get_result__
        @__result ||= Result.new
      end

      def __map_failure_type(arg, type)
        return type if type != :error
        return arg if arg.is_a?(Symbol)
        return :exception if arg.is_a?(Exception)

        type
      end
  end
end
