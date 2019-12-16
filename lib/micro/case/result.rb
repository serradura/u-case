# frozen_string_literal: true

module Micro
  class Case
    class Result
      module DataMethods
        def to_h; data; end

        def [](name); data[name]; end
      end

      class State
        include DataMethods

        attr_reader :value, :type, :data

        def initialize(value, type, data)
          @value, @type, @data = value, type, data
        end

        def to_ary; [value, type]; end
      end

      private_constant :State, :DataMethods

      include DataMethods

      attr_reader :value, :type

      def __set__(is_success, value, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase if !is_success && !is_a_use_case?(use_case)

        @success, @value, @type, @use_case = is_success, value, type, use_case

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

      def data
        return { value => true } if value == type

        value.is_a?(::Hash) ? value : { value: value }
      end

      def on_success(expected_type = nil)
        self.tap { yield(value) if success_type?(expected_type) }
      end

      def on_failure(expected_type = nil)
        return self unless failure_type?(expected_type)

        output =
          expected_type.nil? ? State.new(value, type, data).tap(&:freeze) : value

        self.tap { yield(output, @use_case) }
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

          arg.call(self.value)
        end
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
    end
  end
end
