# frozen_string_literal: true

module Micro
  module Service
    class Result
      InvalidType = TypeError.new('type must be a Symbol'.freeze)
      InvalidService = TypeError.new('service must be a kind or an instance of Micro::Service::Base'.freeze)

      class InvalidAccessToTheServiceObject < StandardError
        MSG = 'only a failure result can access its service object'.freeze

        def initialize(message = MSG); super; end
      end

      attr_reader :value, :type

      def __set__(is_success, value, type, service)
        raise InvalidType unless type.is_a?(Symbol)
        raise InvalidService if !is_success && !is_a_service?(service)

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

        raise InvalidAccessToTheServiceObject
      end

      def on_success(arg = :ok)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg = :error)
        self.tap{ yield(value, @service) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg == :ok || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg == :error || arg == type)
        end

        def is_a_service?(arg)
          (arg.is_a?(Class) && arg < Service::Base) || arg.is_a?(Service::Base)
        end
    end
  end
end
