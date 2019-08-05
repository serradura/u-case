# frozen_string_literal: true

module Micro
  module Service
    class Pipeline
      def self.[](*services)
        new(services)
      end

      def initialize(services)
        @services = Array(services)
      end

      def call(arg={})
        first_result = Micro::Service::Result::Success(arg, type: nil)

        @services.reduce(first_result) do |result, service|
          break result if result.failure?

          service.call(result.value)
        end
      end
    end
  end
end
