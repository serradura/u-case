# frozen_string_literal: true

module Micro
  module Service
    class Pipeline
      INVALID_COLLECTION =
        'argument must be a collection of `Micro::Service::Base` classes'.freeze

      def self.[](*services)
        new(services)
      end

      def initialize(services)
        @services = validate!(services)
      end

      def call(arg={})
        initial_result = Micro::Service::Result::Success(value: arg)

        @services.reduce(initial_result) do |result, service|
          break result if result.failure?
          service.call(result.value)
        end
      end

      private

        def validate!(services)
          Array(services).tap do |collection|
            if collection.any? { |klass| !(klass < ::Micro::Service::Base) }
              raise ArgumentError, INVALID_COLLECTION
            end
          end
        end
    end
  end
end
