# frozen_string_literal: true

module Micro
  module Service
    class Result
      attr_reader :value, :type

      def __set__(is_success, value, type, service)
        raise Error::InvalidResultType unless type.is_a?(Symbol)
        raise Error::InvalidService if !is_success && !is_a_service?(service)

        @success, @value, @type, @service = is_success, value, type, service

        self
      end

      def success?
        @success
      end

      def failure?
        !success?
      end

      def service
        return @service if failure?

        raise Error::InvalidAccessToTheServiceObject
      end

      def on_success(arg = nil)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg = nil)
        self.tap{ yield(value, @service) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg.nil? || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg.nil? || arg == type)
        end

        def is_a_service?(arg)
          (arg.is_a?(Class) && arg < Service::Base) || arg.is_a?(Service::Base)
        end
    end
  end
end
