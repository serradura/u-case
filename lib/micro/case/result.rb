# frozen_string_literal: true

require 'set'

module Micro
  class Case
    class Result
      Kind::Types.add(self)

      @@transition_tracking_disabled = false

      attr_reader :type, :data, :use_case

      alias value data

      def initialize
        @__transitions__ = []
        @__transitions_accessible_attributes__ = {}
      end

      def to_ary
        [data, type]
      end

      def [](key)
        data[key]
      end

      def values_at(*keys)
        data.values_at(*keys)
      end

      def success?
        @success
      end

      def failure?
        !success?
      end

      def on_success(expected_type = nil)
        return self unless __success_type?(expected_type)

        hook_data = expected_type.nil? ? self : data

        yield(hook_data, @use_case)

        self
      end

      def on_failure(expected_type = nil)
        return self unless __failure_type?(expected_type)

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

      def then(use_case = nil, attributes = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise Error::InvalidInvocationOfTheThenMethod if use_case
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !use_case && can_yield_self

          if use_case.is_a?(Proc)
            return failure? ? self : __call_proc(use_case, expected: 'then(-> {})'.freeze)
          end

          # TODO: Test the then method with a Micro::Cases.{flow,safe_flow}() instance.
          raise Error::InvalidInvocationOfTheThenMethod unless ::Micro.case_or_flow?(use_case)

          return self if failure?

          input = attributes.is_a?(Hash) ? self.data.merge(attributes) : self.data

          use_case.__call_and_set_transition__(self, input)
        end
      end

      def |(arg)
        return self if failure?

        return __call_proc(arg, expected: '| -> {}'.freeze) if arg.is_a?(Proc)

        raise Error::InvalidInvocationOfTheThenMethod unless ::Micro.case_or_flow?(arg)

        failure? ? self : arg.__call_and_set_transition__(self, data)
      end

      def transitions
        @__transitions__.clone
      end

      FetchData = -> (data) do
        return data if data.is_a?(Hash)
        return { data => true } if data.is_a?(Symbol)

        { exception: data } if data.is_a?(Exception)
      end

      def __set__(is_success, data, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase unless ::Micro.case?(use_case)

        @success, @type, @use_case = is_success, type, use_case

        @data = FetchData.call(data)

        raise Micro::Case::Error::InvalidResult.new(is_success, type, use_case) unless @data

        __set_transition unless @@transition_tracking_disabled

        self
      end

      def __set_transitions_accessible_attributes__(attributes_data)
        return attributes_data if @@transition_tracking_disabled

        attributes = Utils.symbolize_hash_keys(attributes_data)

        __update_transitions_accessible_attributes(attributes)
      end

      private

        def __call_proc(arg, expected:)
          result = arg.arity.zero? ? arg.call : arg.call(data.clone)

          return result if result.is_a?(Result)

          raise Error::UnexpectedResult.new("#{Result.name}##{expected}")
        end

        def __success_type?(expected_type)
          success? && (expected_type.nil? || expected_type == type)
        end

        def __failure_type?(expected_type)
          failure? && (expected_type.nil? || expected_type == type)
        end

        def __update_transitions_accessible_attributes(attributes)
          @__transitions_accessible_attributes__.merge!(attributes)
          @__transitions_accessible_attributes__
        end

        def __set_transition
          use_case_class = @use_case.class
          use_case_attributes = Utils.symbolize_hash_keys(@use_case.attributes)

          __update_transitions_accessible_attributes(use_case_attributes)

          result = @success ? :success : :failure

          @__transitions__ << {
            use_case: { class: use_case_class, attributes: use_case_attributes },
            result => { type: @type, result: data },
            accessible_attributes: @__transitions_accessible_attributes__.keys
          }
        end

        private_constant :FetchData
    end
  end
end
