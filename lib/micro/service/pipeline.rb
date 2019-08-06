# frozen_string_literal: true

module Micro
  module Service
    module Pipeline
      class Reducer
        def initialize(services)
          @services = services
        end

        def call(arg={})
          @services.reduce(initial_result(arg)) do |result, service|
            break result if result.failure?
            service.call(result.value)
          end
        end

        private

          def initial_result(arg)
            return arg if arg.is_a?(Micro::Service::Result)
            Micro::Service::Result::Success(value: arg)
          end
      end

      private_constant :Reducer

      INVALID_SERVICES =
        'argument must be a collection of `Micro::Service::Base` classes'.freeze

      def self.[](*args)
        self.new(args)
      end

      def self.new(args)
        services = Array(args)

        raise ArgumentError, INVALID_SERVICES if services.any? { |klass| !(klass < ::Micro::Service::Base) }

        Reducer.new(services)
      end
    end
  end
end
