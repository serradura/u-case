# frozen_string_literal: true

require 'set'

module Micro
  class Case
    class Result
      Kind::Types.add(self)

      @@transition_tracking_disabled = false

      def self.disable_transition_tracking
        @@transition_tracking_disabled = true
      end

      attr_reader :type, :data

      alias_method :value, :data

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

      def use_case
        return @use_case if failure?

        raise Error::InvalidAccessToTheUseCaseObject
      end

      def on_success(expected_type = nil)
        yield(data) if success_type?(expected_type)

        self
      end

      def on_failure(expected_type = nil)
        return self unless failure_type?(expected_type)

        hook_data = expected_type.nil? ? self : data

        yield(hook_data, @use_case)

        self
      end

      def on_exception(expected_exception = nil)
        return self unless failure_type?(:exception)

        if !expected_exception || (Kind.is(Exception, expected_exception) && data.fetch(:exception).is_a?(expected_exception))
          yield(data, @use_case)
        end

        self
      end

      def then(arg = nil, attributes = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise Error::InvalidInvocationOfTheThenMethod if arg
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !arg && can_yield_self

          raise Error::InvalidInvocationOfTheThenMethod if !is_a_use_case?(arg)

          return self if failure?

          input = attributes.is_a?(Hash) ? self.data.merge(attributes) : self.data

          arg.__call_and_set_transition__(self, input)
        end
      end

      def transitions
        @__transitions__.clone
      end

      FetchData = -> (data, is_success) do
        return data if data.is_a?(Hash)
        return { data => true } if data.is_a?(Symbol)
        return { exception: data } if data.is_a?(Exception)

        err = is_success ? :InvalidSuccessResult : :InvalidFailureResult

        raise Micro::Case::Error.const_get(err), data
      end

      def __set__(is_success, data, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase if !is_a_use_case?(use_case)

        @success, @type, @use_case = is_success, type, use_case

        @data = FetchData.call(data, is_success)

        __set_transition__ unless @@transition_tracking_disabled

        self
      end

      def __set_transitions_accessible_attributes__(attributes_data)
        return attributes_data if @@transition_tracking_disabled

        __set_transitions_accessible_attributes__!(attributes_data)
      end

      private

        def success_type?(expected_type)
          success? && (expected_type.nil? || expected_type == type)
        end

        def failure_type?(expected_type)
          failure? && (expected_type.nil? || expected_type == type)
        end

        def is_a_use_case?(arg)
          (arg.is_a?(Class) && arg < ::Micro::Case) || arg.is_a?(::Micro::Case)
        end

        def __set_transitions_accessible_attributes__!(attributes_data)
          attributes = Utils.symbolize_hash_keys(attributes_data)

          __update_transitions_accessible_attributes__(attributes)
        end

        def __update_transitions_accessible_attributes__(attributes)
          @__transitions_accessible_attributes__.merge!(attributes)
          @__transitions_accessible_attributes__
        end

        def __set_transition__
          use_case_class = @use_case.class
          use_case_attributes = Utils.symbolize_hash_keys(@use_case.attributes)

          __update_transitions_accessible_attributes__(use_case_attributes)

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
