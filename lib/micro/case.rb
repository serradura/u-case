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
    require 'micro/case/result/contract'
    require 'micro/case/check'
    require 'micro/case/config'
    require 'micro/case/safe'
    require 'micro/case/strict'

    require 'micro/cases'

    class << self
      attr_accessor :check
    end
    self.check = Check::Enabled

    include Micro::Attributes
    include Micro::Attributes::Features::Accept

    def self.call(input = Kind::Empty::HASH)
      result = __new__(Result.new, input).__call__

      return result unless block_given?

      result_wrapper = Result::Wrapper.new(result)

      yield(result_wrapper)

      result_wrapper.output
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

        ::Micro::Case.check.then_use_case_or_flow!(use_case, 'Micro::Case.')

        self.call.then(use_case)
      end
    end

    def self.to_proc
      Proc.new { |arg| call(arg) }
    end

    def self.flow(*args, transaction: nil, steps: nil)
      ::Micro::Case.check.flow_steps_kwarg!(args.empty? ? nil : args, steps, "#{self.name}.flow")

      @__flow_use_cases = Cases::Utils.map_use_cases(steps || args)
      @__flow_transaction = transaction
    end

    def self.results(&block)
      raise ArgumentError, 'a block is required'.freeze unless block
      raise ArgumentError, 'must be called on a Micro::Case subclass, not on Micro::Case itself'.freeze if self == ::Micro::Case

      @__results_contract = Result::Contract.define(&block)
    end

    def self.__results_contract__
      return @__results_contract if defined?(@__results_contract)

      parent = superclass
      parent.respond_to?(:__results_contract__) ? parent.__results_contract__ : nil
    end

    def self.transaction(with:)
      ::Micro::Case.check.transaction_owner!(with)

      @__transaction_class = with
    end

    def self.__transaction_class__
      return @__transaction_class if defined?(@__transaction_class)

      parent = superclass
      parent.respond_to?(:__transaction_class__) ? parent.__transaction_class__ : nil
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

      @__flow = __flow_builder__.build(args, transaction: __resolved_flow_transaction)
    end

    private_class_method def self.__flow_transaction
      return @__flow_transaction if defined?(@__flow_transaction)
    end

    private_class_method def self.__resolved_flow_transaction
      return __transaction_class__ || true if __flow_transaction == true

      __flow_transaction
    end

    FLOW_STEP = 'Self'.freeze

    private_constant :FLOW_STEP

    def self.__call__!
      return const_get(FLOW_STEP) if const_defined?(FLOW_STEP, false)

      class_eval("class #{FLOW_STEP} < #{self.name}; private def __call; __call_use_case; end; end; #{FLOW_STEP}")
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
      ::Micro::Case.check.result_instance!(result)
      ::Micro::Case.check.result_not_defined!(defined?(@__result))

      @__result = result

      self
    end

    private

      def call(use_case, defaults = Kind::Empty::HASH)
        ::Micro::Case.check.use_case_or_flow!(use_case)

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
        return __failure_from_attributes_errors if __attributes_errors_present?

        result = call!

        ::Micro::Case.check.expected_result!(result, "#{self.class.name}#call!")

        result
      end

      def __attributes_errors_present?
        attributes_errors?
      end

      def __failure_from_attributes_errors
        __get_result(
          false,
          { errors: attributes_errors },
          Config.instance.activemodel_validation_errors_failure
        )
      end

      def __call_the_use_case_flow?
        self.class.__flow_get__
      end

      def __call_the_use_case_flow
        self.class.__flow_get__.call!(input: @__input, result: @__result)
      end

      def Success(type = :ok, result: nil)
        value = result || type

        ::Micro::Case.check.results_contract!(self.class, :success, type, value)

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

        ::Micro::Case.check.results_contract!(self.class, :failure, type, value)

        __get_result(false, value, type)
      end

      def Check(type = nil, result: nil, on: Kind::Empty::HASH)
        result_key = type || :check

        if value
          result = on[:success] || { result_key => true }

          Success(type || :ok, result: result)
        else
          result = on[:failure] || { result_key => false }

          Failure(type || :error, result: result)
        end
      end

      def __get_result(is_success, value, type)
        @__result.__set__(is_success, value, type, self)
      end

      def transaction(adapter = nil, with: nil)
        # Backward-compat shim for the pre-5.6.0 positional form:
        #   transaction(:activerecord) { ... }
        # The `:activerecord` value was the only positional value the
        # helper ever accepted on prior versions. Anything else raises.
        if adapter
          raise ArgumentError,
            "transaction(#{adapter.inspect}) is not supported; use transaction(with: SomeARClass) or transaction without arguments" unless adapter == :activerecord
        end

        ::Micro::Case.check.transaction_owner!(with) if with

        owner = with || self.class.__transaction_class__

        if owner.nil?
          ::Micro::Case.check.activerecord_loaded!
          owner = Config.instance.default_transaction_class.call
        end

        result = nil

        owner.transaction do
          result = yield

          raise ::ActiveRecord::Rollback if result.failure?
        end

        result
      end

      alias_method :rollback_on_failure, :transaction

    private_constant :MapFailureType, :INVALID_INVOCATION_OF_THE_THEN_METHOD
  end

  def self.case?(arg)
    arg.is_a?(Class) && arg < Case
  end

  def self.case_or_flow?(arg)
    case?(arg) || arg.is_a?(Cases::Flow)
  end
end
