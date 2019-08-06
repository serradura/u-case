# frozen_string_literal: true

module Micro
  module Service
    class Result
      include Micro::Attributes.with(:initialize)

      attributes :success, :type, :value

      INVALID_TYPE =  "#{self.name}#type must be nil or a symbol".freeze

      def self.Type(arg)
        return arg if arg.nil? || arg.is_a?(Symbol)
        raise TypeError, INVALID_TYPE
      end

      def self.Success(value:, type: nil)
        self.new(success: true, type: Type(type), value: value)
      end

      def self.Failure(value:, type: nil)
        self.new(success: false, type: Type(type), value: value)
      end

      def success?
        success
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

      module Helpers
        private

          def Success(arg=nil)
            value, type = block_given? ? [yield, arg] : [arg, nil]
            Result::Success(value: value, type: type)
          end

          def Failure(arg=nil)
            value, type = block_given? ? [yield, arg] : [arg, nil]
            Result::Failure(value: value, type: type)
          end
      end
    end
  end
end
