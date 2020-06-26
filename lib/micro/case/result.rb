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

      class Data
        attr_reader :value, :type

        def initialize(value, type)
          @value, @type = value, type
        end

        def to_ary; [value, type]; end
      end

      private_constant :Data

      attr_reader :value, :type

      def initialize
        @__transitions__ = {}
        @__transitions_accessible_attributes__ = Set.new
      end

      def __set__(is_success, value, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase if !is_a_use_case?(use_case)

        @success, @value, @type, @use_case = is_success, value, type, use_case

        __set_transition__ unless @@transition_tracking_disabled

        self
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
        yield(value) if success_type?(expected_type)

        self
      end

      def on_failure(expected_type = nil)
        return self unless failure_type?(expected_type)

        data = expected_type.nil? ? Data.new(value, type).tap(&:freeze) : value

        yield(data, @use_case)

        self
      end

      def on_exception(expected_exception = nil)
        return self unless failure_type?(:exception)

        if !expected_exception || (Kind.is(Exception, expected_exception) && value.is_a?(expected_exception))
          yield(value, @use_case)
        end

        self
      end

      def then(arg = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise Error::InvalidInvocationOfTheThenMethod if arg
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !arg && can_yield_self

          raise Error::InvalidInvocationOfTheThenMethod if !is_a_use_case?(arg)

          return self if failure?

          arg.__call_and_set_transition__(self, self.value)
        end
      end

      def transitions
        return [] if @__transitions__.empty?

        @__transitions__.map { |_use_case, transition| transition }
      end

      def __set_transitions_accessible_attributes__(attribute_names)
        return if @@transition_tracking_disabled

        __set_transitions_accessible_attributes__!(
          attribute_names.map!(&:to_sym)
        )
      end

      private

        def __set_transitions_accessible_attributes__!(attribute_names)
          @__transitions_accessible_attributes__.merge(
            attribute_names
          )
        end

        def success_type?(expected_type)
          success? && (expected_type.nil? || expected_type == type)
        end

        def failure_type?(expected_type)
          failure? && (expected_type.nil? || expected_type == type)
        end

        def is_a_use_case?(arg)
          (arg.is_a?(Class) && arg < ::Micro::Case) || arg.is_a?(::Micro::Case)
        end

        def __set_transition__
          use_case_class = @use_case.class
          use_case_attributes = Utils.symbolize_hash_keys(@use_case.attributes)

          __set_transitions_accessible_attributes__!(use_case_attributes.keys)

          result = @success ? :success : :failure
          transition = {
            use_case: { class: use_case_class, attributes: use_case_attributes },
            result => { type: @type, value: @value },
            accessible_attributes: @__transitions_accessible_attributes__.to_a
          }

          @__transitions__[use_case_class] = transition
        end
    end
  end
end
