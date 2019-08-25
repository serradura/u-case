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

        def to_proc
          Proc.new { |arg| call(arg) }
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
              instance = service.__new__(result, result.value)
              instance.call
            rescue => exception
              raise exception if Error::ByWrongUsage.check(exception)
              result.__set__(false, exception, :exception, instance)
            end
          end
      end
    end
  end
end
