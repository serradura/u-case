# frozen_string_literal: true

module Micro
  module Service
    class Result
      InvalidType = TypeError.new('type must be nil or a symbol'.freeze)

      attr_reader :value, :type

      def __set__(is_success, value, type)
        raise InvalidType unless type.nil? || type.is_a?(Symbol)

        @success, @value, @type = is_success, value, type

        self
      end

      def success?
        @success
      end

      def failure?
        !success?
      end

      def on_success(arg=nil)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg=nil)
        self.tap{ yield(value) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg.nil? || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg.nil? || arg == type)
        end
    end
  end
end
