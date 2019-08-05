# frozen_string_literal: true

module Micro
  module Service
    class Result
      include Micro::Attributes.with(:initialize)

      def self.Success(value, type:)
        self.new(success: true, type: type, value: value)
      end

      def self.Failure(value, type:)
        self.new(success: false, type: type, value: value)
      end

      attributes :success, :type, :value

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

          def Success(value=nil, type: nil)
            yielded_value = yield if block_given?
            Result::Success(yielded_value || value, type: type)
          end

          def Failure(value=nil, type: nil)
            yielded_value = yield if block_given?
            Result::Failure(yielded_value || value, type: type)
          end
      end
    end
  end
end
