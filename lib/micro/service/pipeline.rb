# frozen_string_literal: true

module Micro
  module Service
    module Pipeline
      class Reducer
        attr_reader :services

        INVALID_SERVICES =
          'argument must be a collection of `Micro::Service::Base` classes'.freeze

        def self.map_services(arg)
          return arg.services if arg.is_a?(Reducer)
          return arg.__pipeline__.services if arg.is_a?(Class) && arg < Micro::Service::Pipeline
          Array(arg)
        end

        def self.build(args)
          services = Array(args).flat_map { |arg| map_services(arg) }

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

        def >>(arg)
          Reducer.build(services + self.class.map_services(arg))
        end

        private

          def initial_result(arg)
            return arg if arg.is_a?(Micro::Service::Result)

            Micro::Service::Result::Success[value: arg]
          end
      end

      module ClassMethods
        def __pipeline__
          @__pipeline
        end

        def pipeline(*args)
          @__pipeline = Reducer.build(args)
        end

        def call(options={})
          new(options).call
        end
      end

      private_constant :ClassMethods

      def self.[](*args)
        Reducer.build(args)
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval('def initialize(options); @options = options; end')
      end

      def call
        self.class.__pipeline__.call(@options)
      end
    end
  end
end
