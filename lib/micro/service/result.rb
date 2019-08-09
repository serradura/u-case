# frozen_string_literal: true

module Micro
  module Service
    class Result
      module Type
        INVALID = 'type must be nil or a symbol'.freeze

        def self.[](arg)
          return arg if arg.nil? || arg.is_a?(Symbol)
          raise TypeError, INVALID
        end
      end

      private_constant :Type

      include Micro::Attributes.with(:strict_initialize)

      def self.[](value:, type: nil)
        new(value: value, type: Type[type])
      end

      attributes :type, :value

      def success?
        raise NotImplementedError
      end

      def failure?
        !success?
      end

      def on_success(arg=nil)
        self.tap { yield(value) if success_type?(arg) }
      end

      def on_failure(arg=nil)
        self.tap{ yield(value) if failure_type?(arg) }
      end

      private

        def success_type?(arg)
          success? && (arg.nil? || arg == type)
        end

        def failure_type?(arg)
          failure? && (arg.nil? || arg == type)
        end
    end
  end
end
