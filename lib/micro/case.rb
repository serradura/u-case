# frozen_string_literal: true

require 'kind'
require 'micro/attributes'

module Micro
  class Case
    require 'micro/case/version'
    require 'micro/case/utils'
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

    def self.__call_and_set_transition__(result, arg)
      if arg.respond_to?(:keys)
        result.__set_transitions_accessible_attributes__(arg.keys)
      end

      __new__(result, arg).call
    end

    FLOW_STEP = 'Flow_Step'.freeze

    private_constant :FLOW_STEP

    def self.__call!
      return const_get(FLOW_STEP) if const_defined?(FLOW_STEP, false)

      class_eval("class #{FLOW_STEP} < #{self.name}; private def __call; __call_use_case; end; end")
    end

    def self.call!
      self
    end

    def self.inherited(subclass)
      subclass.attributes(self.attributes_data({}))
      subclass.extend ::Micro::Attributes.const_get('Macros::ForSubclasses'.freeze)

      if self.send(:__flow_use_cases) && !subclass.name.to_s.end_with?(FLOW_STEP)
        raise "Wooo, you can't do this! Inherits from a use case which has an inner flow violates "\
          "one of the project principles: Solve complex business logic, by allowing the composition of use cases. "\
          "Instead of doing this, declare a new class/constant with the steps needed.\n\n"\
          "Related issue: https://github.com/serradura/u-case/issues/19\n"
      end
    end

    def self.__flow_reducer
      Flow::Reducer
    end

    def self.__flow_get
      return @__flow if defined?(@__flow)
    end

    private_class_method def self.__flow_use_cases
      return @__flow_use_cases if defined?(@__flow_use_cases)
    end

    private_class_method def self.__flow_use_cases_get
      Array(__flow_use_cases)
        .map { |use_case| use_case == self ? self.__call! : use_case }
    end

    private_class_method def self.__flow_use_cases_set(args)
      @__flow_use_cases = args
    end

    private_class_method def self.__flow_set(args)
      return if __flow_get

      def self.use_cases; __flow_get.use_cases; end

      self.class_eval('def use_cases; self.class.use_cases; end')

      @__flow = __flow_reducer.build(args)
    end

    def self.__flow_set!
      __flow_set(__flow_use_cases_get) if !__flow_get && __flow_use_cases
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
      raise Error::ResultIsAlreadyDefined if defined?(@__result)

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

        __get_result_with(true, value, type)
      end

      def Failure(arg = :error)
        value = block_given? ? yield : arg
        type = __map_failure_type(value, block_given? ? arg : :error)

        __get_result_with(false, value, type)
      end

      def __map_failure_type(arg, type)
        return type if type != :error
        return arg if arg.is_a?(Symbol)
        return :exception if arg.is_a?(Exception)

        type
      end

      def __get_result__
        @__result ||= Result.new
      end

      def __get_result_with(is_success, value, type)
        __get_result__.__set__(is_success, value, type, self)
      end
  end
end
