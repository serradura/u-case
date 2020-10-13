# frozen_string_literal: true

require 'set'

module Micro
  class Case
    class Result
      require 'micro/case/result/wrapper'
      require 'micro/case/result/transitions'

      Kind::Types.add(self)

      INVALID_INVOCATION_OF_THE_THEN_METHOD =
        Error::InvalidInvocationOfTheThenMethod.new("#{self.name}#")

      @@transitions_enabled = true

      def self.transitions_enabled?
        @@transitions_enabled
      end

      attr_reader :type, :data, :use_case

      alias value data

      def initialize(transitions_mapper = Transitions::MapEverything)
        enable_transitions = @@transitions_enabled

        @__is_unknown = true
        @__accumulated_data = {}
        @__tracked_use_cases = Set.new
        @__accessible_attributes = {}

        @__transitions = enable_transitions ? [] : Kind::Empty::ARRAY
        @__transitions_mapper = transitions_mapper if enable_transitions
      end

      def to_ary
        [data, type]
      end

      def to_sym
        @__success ? :success : :failure
      end

      def [](key)
        data[key]
      end

      def values_at(*keys)
        data.values_at(*keys)
      end

      def key?(key)
        data.key?(key)
      end

      def value?(value)
        data.value?(value)
      end

      def slice(*keys)
        Utils::Hashes.slice(data, keys)
      end

      def success?
        @__success
      end

      def failure?
        !success?
      end

      def unknown?
        @__is_unknown
      end

      def accessible_attributes
        @__accessible_attributes.keys
      end

      def on_success(expected_type = nil)
        return self unless __success_type?(expected_type)

        @__is_unknown = false
        hook_data = expected_type.nil? ? self : data

        yield(hook_data, @use_case)

        self
      end

      def on_failure(expected_type = nil)
        return self unless __failure_type?(expected_type)

        @__is_unknown = false
        hook_data = expected_type.nil? ? self : data

        yield(hook_data, @use_case)

        self
      end

      def on_exception(expected_exception = nil)
        return self unless __failure_type?(:exception)

        if !expected_exception || (Kind.is(Exception, expected_exception) && data.fetch(:exception).is_a?(expected_exception))
          yield(data, @use_case)
        end

        self
      end

      def on_unknown
        return self unless unknown?

        yield(self, @use_case)

        self
      end

      def then(use_case = nil, attributes = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise INVALID_INVOCATION_OF_THE_THEN_METHOD if use_case
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !use_case && can_yield_self
          return failure? ? self : __call_proc(use_case, 'then(-> {})'.freeze) if use_case.is_a?(Proc)
          return failure? ? self : __call_method(use_case, attributes) if use_case.is_a?(Method)

          raise INVALID_INVOCATION_OF_THE_THEN_METHOD unless ::Micro.case_or_flow?(use_case)

          return self if failure?

          input = attributes.is_a?(Hash) ? self.data.merge(attributes) : self.data

          if use_case.is_a?(::Micro::Cases::Flow)
            use_case.call!(input: input, result: self)
          else
            use_case.__new__(self, input).__call__
          end
        end
      end

      def |(arg)
        return self if failure?

        return __call_proc(arg, '| -> {}'.freeze) if arg.is_a?(Proc)
        return __call_method(arg) if arg.is_a?(Method)

        raise INVALID_INVOCATION_OF_THE_THEN_METHOD unless ::Micro.case_or_flow?(arg)

        failure? ? self : arg.__new__(self, data).__call__
      end

      def transitions
        @__transitions.dup
      end

      FetchData = -> (data) do
        return data if data.is_a?(Hash)
        return { data => true } if data.is_a?(Symbol)

        { exception: data } if data.is_a?(Exception)
      end

      def __set__(is_success, data, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase unless use_case.is_a?(::Micro::Case)

        @__success, @type, @use_case = is_success, type, use_case

        @data = FetchData.call(data).freeze

        raise Micro::Case::Error::InvalidResult.new(is_success, type, use_case) unless @data

        @__accumulated_data.merge!(@data)

        use_case_attributes = Utils::Hashes.symbolize_keys(@use_case.attributes)

        unless @__tracked_use_cases.member?(use_case_class = @use_case.class)
          @__tracked_use_cases.add(use_case_class)

          __update_accessible_attributes(use_case_attributes)
        end

        __set_transition(use_case_attributes) unless @__transitions.frozen?

        self
      end

      def __set_accessible_attributes__(arg)
        return arg unless arg.is_a?(Hash)

        attributes = Utils::Hashes.symbolize_keys(arg)

        __update_accessible_attributes(attributes)
        __fetch_accessible_attributes
      end

      private

        def __update_accessible_attributes(attributes)
          @__accessible_attributes.merge!(attributes)
        end

        def __fetch_accessible_attributes
          @__accessible_attributes.dup
        end

        def __call_proc(fn, expected)
          __update_accessible_attributes(@__accumulated_data)

          result = fn.arity.zero? ? fn.call : fn.call(__fetch_accessible_attributes)

          return self if result === self

          raise Error::UnexpectedResult.new("#{Result.name}##{expected}")
        end

        def __call_method(methd, attributes = nil)
          __update_accessible_attributes(attributes ? attributes.merge(@__accumulated_data) : @__accumulated_data)

          result = methd.arity.zero? ? methd.call : methd.call(**__fetch_accessible_attributes)

          return self if result === self

          raise Error::UnexpectedResult.new("#{use_case.class.name}#method(:#{methd.name})")
        end

        def __success_type?(expected_type)
          success? && (expected_type.nil? || expected_type == type)
        end

        def __failure_type?(expected_type)
          failure? && (expected_type.nil? || expected_type == type)
        end

        def __set_transition(use_case_attributes)
          @__transitions << @__transitions_mapper.call(self, use_case_attributes)
        end

      private_constant :FetchData, :INVALID_INVOCATION_OF_THE_THEN_METHOD
    end
  end
end
