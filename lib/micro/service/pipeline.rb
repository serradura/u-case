# frozen_string_literal: true

module Micro
  module Service
    module Pipeline
      class Reducer
        INVALID_SERVICES =
          'argument must be a collection of `Micro::Service::Base` classes'.freeze

        def self.build(args)
          services = Array(args)

          raise ArgumentError, INVALID_SERVICES if services.any? { |klass| !(klass < ::Micro::Service::Base) }

          new(services)
        end

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
            Micro::Service::Result::Success[value: arg]
          end
      end

      private_constant :Reducer

      module Macros
        def pipeline(*args)
          @pipeline = Reducer.build(args)
        end

        def pipeline_call(options)
          @pipeline.call(options)
        end

        def call(options={})
          new(options).call
        end
      end

      private_constant :Macros

      def self.[](*args)
        Reducer.build(args)
      end

      def self.included(base)
        base.extend(Macros)
        base.class_eval('def initialize(options); @options = options; end')
      end

      def call
        self.class.pipeline_call(@options)
      end
    end
  end
end
