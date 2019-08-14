# frozen_string_literal: true

module Micro
  module Service
    module Pipeline
      class Reducer
        attr_reader :services

        InvalidServices = ArgumentError.new('argument must be a collection of `Micro::Service::Base` classes'.freeze)

        private_constant :InvalidServices

        def self.map_services(arg)
          return arg.services if arg.is_a?(Reducer)
          return arg.__pipeline__.services if arg.is_a?(Class) && arg < Micro::Service::Pipeline
          Array(arg)
        end

        def self.build(args)
          services = Array(args).flat_map { |arg| map_services(arg) }

          raise InvalidServices if services.any? { |klass| !(klass < ::Micro::Service::Base) }

          new(services)
        end

        def initialize(services)
          @services = services
        end

        def call(arg={})
          @services.reduce(initial_result(arg)) do |result, service|
            break result if result.failure?
            service.__new__(result, result.value).call
          end
        end

        def >>(arg)
          Reducer.build(services + self.class.map_services(arg))
        end

        private

          def initial_result(arg)
            return arg.call if arg_to_call?(arg)
            return arg if arg.is_a?(Micro::Service::Result)
            result = Micro::Service::Result.new
            result.__set__(true, arg, nil)
          end

          def arg_to_call?(arg)
            return true if arg.is_a?(Micro::Service::Base) || arg.is_a?(Reducer)
            return true if arg.is_a?(Class) && (arg < Micro::Service::Base || arg < Micro::Service::Pipeline)
            return false
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

      UndefinedPipeline = ArgumentError.new("This class hasn't declared its pipeline. Please, use the `pipeline()` macro to define one.".freeze)

      private_constant :UndefinedPipeline

      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval(<<-RUBY)
        def initialize(options)
          @options = options
          pipeline = self.class.__pipeline__
          raise UndefinedPipeline unless pipeline
        end
        RUBY
      end

      def call
        self.class.__pipeline__.call(@options)
      end
    end
  end
end
