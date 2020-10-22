# frozen_string_literal: true

require 'kind'
require 'micro/attributes'

require 'micro/case/version'

module Micro
  class Case
    require 'micro/cases/utils'
    require 'micro/case/utils'
    require 'micro/case/error'
    require 'micro/case/result'
    require 'micro/case/safe'
    require 'micro/case/strict'
    require 'micro/case/config'

    require 'micro/cases'

    include Micro::Attributes

    def self.call(input = Kind::Empty::HASH)
      result = __new__(Result.new, input).__call__

      return result unless block_given?

      yield Result::Wrapper.new(result)
    end

    INVALID_INVOCATION_OF_THE_THEN_METHOD =
      Error::InvalidInvocationOfTheThenMethod.new("#{self.name}.")

    def self.then(use_case = nil, &block)
      can_yield_self = respond_to?(:yield_self)

      if block
        raise INVALID_INVOCATION_OF_THE_THEN_METHOD if use_case
        raise NotImplementedError if !can_yield_self

        yield_self(&block)
      else
        return yield_self if !use_case && can_yield_self

        raise INVALID_INVOCATION_OF_THE_THEN_METHOD unless ::Micro.case_or_flow?(use_case)

        self.call.then(use_case)
      end
    end

    def self.to_proc
      Proc.new { |arg| call(arg) }
    end

    def self.flow(*args)
      @__flow_use_cases = Cases::Utils.map_use_cases(args)
    end

    class << self
      alias __call__ call

      def config
        yield(Config.instance)
      end

      def call!
        self
      end
    end

    def self.inherited(subclass)
      subclass.__attributes_set_after_inherit__(self.__attributes_data__)

      subclass.extend ::Micro::Attributes.const_get('Macros::ForSubclasses'.freeze)

      if self.send(:__flow_use_cases) && !subclass.name.to_s.end_with?(FLOW_STEP)
        raise "Wooo, you can't do this! Inherits from a use case which has an inner flow violates "\
          "one of the project principles: Solve complex business logic, by allowing the composition of use cases. "\
          "Instead of doing this, declare a new class/constant with the steps needed.\n\n"\
          "Related issue: https://github.com/serradura/u-case/issues/19\n"
      end
    end

    def self.__new__(result, arg)
      input = result.__set_accessible_attributes__(arg)

      new(input).__set_result__(result)
    end

    private_class_method :new

    def self.__flow_builder__
      Cases::Flow
    end

    def self.__flow_get__
      return @__flow if defined?(@__flow)
    end

    private_class_method def self.__flow_set(args)
      return if __flow_get__

      def self.use_cases; __flow_get__.use_cases; end

      self.class_eval('def use_cases; self.class.use_cases; end')

      @__flow = __flow_builder__.build(args)
    end

    FLOW_STEP = 'Self'.freeze

    private_constant :FLOW_STEP

    def self.__call__!
      return const_get(FLOW_STEP) if const_defined?(FLOW_STEP, false)

      class_eval("class #{FLOW_STEP} < #{self.name}; private def __call; __call_use_case; end; end")
    end

    private_class_method def self.__flow_use_cases
      return @__flow_use_cases if defined?(@__flow_use_cases)
    end

    private_class_method def self.__flow_use_cases_get
      Array(__flow_use_cases)
        .map { |use_case| use_case == self ? self.__call__! : use_case }
    end

    def self.__flow_set__!
      __flow_set(__flow_use_cases_get) if !__flow_get__ && __flow_use_cases
    end

    InspectKey = :__inspect_key__ # :nodoc:

    def self.inspect
      ids = (Thread.current[InspectKey] ||= [])

      if ids.include?(object_id)
        return sprintf('#<%s: ...>', self)
      end

      begin
        ids << object_id

        if __flow_use_cases
          return '<%s (%s) use_cases=%s>' % [self, __flow_builder__, @__flow_use_cases]
        else
          return '<%s (%s) attributes=%s>' % [self, self.superclass, attributes]
        end
      ensure
        ids.pop
      end
    end

    def initialize(input)
      __setup_use_case(input)
    end

    def call!
      raise NotImplementedError
    end

    def __call__
      __call_the_use_case_or_its_flow
    end

    def __set_result__(result)
      raise Error::InvalidResultInstance unless result.is_a?(Result)
      raise Error::ResultIsAlreadyDefined if defined?(@__result)

      @__result = result

      self
    end

    private

      def call(use_case, defaults = Kind::Empty::HASH)
        raise Error::InvalidUseCase unless ::Micro.case_or_flow?(use_case)

        input =
          defaults.empty? ? attributes : attributes.merge(Utils::Hashes.stringify_keys(defaults))

        use_case.__new__(@__result, input).__call__
      end

      def apply(name)
        method(name)
      end

      def __call_the_use_case_or_its_flow
        return __call_the_use_case_flow if __call_the_use_case_flow?

        __call_use_case
      end

      def __setup_use_case(input)
        self.class.__flow_set__!

        @__input = input

        self.attributes = input
      end

      def __call_use_case
        result = call!

        return result if result.is_a?(Result)

        raise Error::UnexpectedResult.new("#{self.class.name}#call!")
      end

      def __call_the_use_case_flow?
        self.class.__flow_get__
      end

      def __call_the_use_case_flow
        self.class.__flow_get__.call(@__input)
      end

      def Success(type = :ok, result: nil)
        value = result || type

        __get_result(true, value, type)
      end

      MapFailureType = -> (value, type) do
        return type if type != :error
        return value if value.is_a?(Symbol)
        return :exception if value.is_a?(Exception)

        type
      end

      def Failure(type = :error, result: nil)
        value = result || type

        type = MapFailureType.call(value, type)

        __get_result(false, value, type)
      end

      def __get_result(is_success, value, type)
        @__result.__set__(is_success, value, type, self)
      end

      def transaction(adapter = :activerecord)
        raise NotImplementedError unless adapter == :activerecord

        result = nil

        ActiveRecord::Base.transaction do
          result = yield

          raise ActiveRecord::Rollback if result.failure?
        end

        result
      end

    private_constant :MapFailureType, :INVALID_INVOCATION_OF_THE_THEN_METHOD
  end

  def self.case?(arg)
    arg.is_a?(Class) && arg < Case
  end

  def self.case_or_flow?(arg)
    case?(arg) || arg.is_a?(Cases::Flow)
  end
end
