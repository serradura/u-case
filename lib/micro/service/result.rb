# frozen_string_literal: true

module Micro
  module Service
    class Result
      InvalidType = TypeError.new('type must be a Symbol'.freeze)

      attr_reader :value, :type

      def __set__(is_success, value, type)
        raise InvalidType unless type.is_a?(Symbol)

        @success, @value, @type = is_success, value, type

        self
      end

      def success?
        @success
      end

      def failure?
        !success?
      end

      def on_success(arg = :ok)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg = :error)
        self.tap{ yield(value) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg == :ok || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg == :error || arg == type)
        end
    end
  end
end
