# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Data
        attr_reader :value, :type

        def initialize(value, type)
          @value, @type = value, type
        end

        def to_ary; [value, type]; end
      end

      private_constant :Data

      attr_reader :value, :type

      def __set__(is_success, value, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase if !is_a_use_case?(use_case)

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

      def on_success(expected_type = nil)
        self.tap { yield(value) if success_type?(expected_type) }
      end

      def on_failure(expected_type = nil)
        return self unless failure_type?(expected_type)

        data = expected_type.nil? ? Data.new(value, type).tap(&:freeze) : value

        self.tap { yield(data, @use_case) }
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
