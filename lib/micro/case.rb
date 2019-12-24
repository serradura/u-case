# frozen_string_literal: true

require 'micro/attributes'
# frozen_string_literal: true

module Micro
  class Case
    require_relative 'case/version'
    require_relative 'case/result'
    require_relative 'case/error'
    require_relative 'case/safe'
    require_relative 'case/strict'
    require_relative 'case/flow/reducer'
    require_relative 'case/flow'
    require_relative 'case/safe/flow'

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

    def self.__call!
      return const_get(:Flow_Step) if const_defined?(:Flow_Step)

      const_set(:Flow_Step, Class.new(self) do
        private def __call
          __call_use_case
        end
      end)
    end

    def self.call!
      self
    end

    def self.__flow_reducer
      Flow::Reducer
    end

    def self.__flow_get
      @__flow
    end

    private_class_method def self.__flow_use_cases_set(args)
      @__flow_use_cases = args
    end

    private_class_method def self.__flow_use_cases_get
      Array(@__flow_use_cases)
        .map { |use_case| use_case == self ? self.__call! : use_case }
    end

    private_class_method def self.__flow_set(args)
      return if __flow_get

      def self.use_cases; __flow_get.use_cases; end

      self.class_eval('def use_cases; self.class.use_cases; end')

      @__flow = __flow_reducer.build(args)
    end

    def self.__flow_set!
      __flow_set(__flow_use_cases_get) if !__flow_get && @__flow_use_cases
    end

    def self.flow(*args)
      __flow_use_cases_set(args)
    end

    def initialize(input)
      __setup_use_case(input)
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

      def __setup_use_case(input)
        self.class.__flow_set!

        @__input = input

        self.attributes = input
      end

      def __call
        return __call_use_case_flow if __call_use_case_flow?

        __call_use_case
      end

      def __call_use_case
        result = call!

        return result if result.is_a?(Result)

        raise Error::UnexpectedResult.new(self.class)
      end

      def __call_use_case_flow?
        self.class.__flow_get
      end

      def __call_use_case_flow
        self.class.__flow_get.call(@__input)
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
