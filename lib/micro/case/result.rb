# frozen_string_literal: true

module Micro
  module Case
    class Result
      attr_reader :value, :type

      def __set__(is_success, value, type, use_case)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidUseCase if !is_success && !is_an_use_case?(use_case)

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

      def on_success(arg = nil)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg = nil)
        self.tap{ yield(value, @use_case) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg.nil? || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg.nil? || arg == type)
        end

        def is_an_use_case?(arg)
          (arg.is_a?(Class) && arg < Case::Base) || arg.is_a?(Case::Base)
        end
    end
  end
end
