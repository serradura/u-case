# frozen_string_literal: true

module Micro
  module Service
    module Pipeline
      class Reducer
        attr_reader :services
        def self.map_services(arg)
          return arg.services if arg.is_a?(Reducer)
          return arg.__pipeline__.services if arg.is_a?(Class) && arg < Micro::Service::Pipeline
          Array(arg)
        end

        def self.build(args)
          services = Array(args).flat_map { |arg| map_services(arg) }

          raise Error::InvalidServices if services.any? { |klass| !(klass < ::Micro::Service::Base) }

          new(services)
        end

        def initialize(services)
          @services = services
        end

        def call(arg = {})
          @services.reduce(initial_result(arg)) do |result, service|
            break result if result.failure?
            service.__new__(result, result.value).call
          end
        end

        def >>(arg)
          self.class.build(services + self.class.map_services(arg))
        end

        def &(arg)
          raise NoMethodError, "undefined method `&' for #{self.inspect}. Please, use the method `>>' to avoid this error."
        end

        private

          def initial_result(arg)
            return arg.call if arg_to_call?(arg)
            return arg if arg.is_a?(Micro::Service::Result)
            result = Micro::Service::Result.new
            result.__set__(true, arg, :ok, nil)
          end

          def arg_to_call?(arg)
            return true if arg.is_a?(Micro::Service::Base) || arg.is_a?(Reducer)
            return true if arg.is_a?(Class) && (arg < Micro::Service::Base || arg < Micro::Service::Pipeline)
            return false
          end
      end

      class SafeReducer < Reducer
        MISSING_KEYWORD = 'missing keyword'.freeze
        ARGUMENT_MUST_BE_A_HASH = 'argument must be a Hash'.freeze

        def call(arg = {})
          @services.reduce(initial_result(arg)) do |result, service|
            break result if result.failure?
            service_result(service, result)
          end
        end

        alias_method :&, :>>

        def >>(arg)
          raise NoMethodError, "undefined method `>>' for #{self.inspect}. Please, use the method `&' to avoid this error."
        end

        private

          def service_result(service, result)
            begin
              service.__new__(result, result.value).call
            rescue => exception
              raise exception if Error::ByWrongUsage.check(exception)
              result.__set__(false, exception, :exception, service)
            end
          end
      end

      module ClassMethods
        def __pipeline__
          @__pipeline
        end

        def pipeline(*args)
          @__pipeline = pipeline_reducer.build(args)
        end

        def call(options = {})
          new(options).call
        end
      end

      CONSTRUCTOR = <<-RUBY
      def initialize(options)
        @options = options
        pipeline = self.class.__pipeline__
        raise Error::UndefinedPipeline unless pipeline
      end
      RUBY

      private_constant :ClassMethods, :CONSTRUCTOR

      def self.included(base)
        def base.pipeline_reducer; Reducer; end
        base.extend(ClassMethods)
        base.class_eval(CONSTRUCTOR)
      end

      def self.[](*args)
        Reducer.build(args)
      end

      def call
        self.class.__pipeline__.call(@options)
      end

      module Safe
        def self.included(base)
          base.send(:include, Micro::Service::Pipeline)
          def base.pipeline_reducer; SafeReducer; end
        end

        def self.[](*args)
          SafeReducer.build(args)
        end
      end
    end
  end
end
