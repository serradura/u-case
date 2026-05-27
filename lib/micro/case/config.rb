# frozen_string_literal: true

require 'singleton'

module Micro
  class Case
    class Config
      include Singleton

      def enable_transitions=(value)
        Micro::Case::Result.class_variable_set(
          :@@transitions_enabled, Kind::Boolean[value]
        )
      end

      def disable_safe_features=(value)
        @disable_safe_features = Kind::Boolean[value]
      end

      def disable_safe_features
        return @disable_safe_features if defined?(@disable_safe_features)

        @disable_safe_features = false
      end

      def disable_runtime_checks=(value)
        @disable_runtime_checks = Kind::Boolean[value]

        ::Micro::Case.check = @disable_runtime_checks ? ::Micro::Case::Check::Disabled : ::Micro::Case::Check::Enabled
      end

      def disable_runtime_checks
        return @disable_runtime_checks if defined?(@disable_runtime_checks)

        @disable_runtime_checks = false
      end

      def enable_activemodel_validation=(value)
        return unless Kind::Boolean[value]

        require 'micro/case/with_activemodel_validation'
      end

      def set_activemodel_validation_errors_failure=(value)
        return unless value

        @activemodel_validation_errors_failure = Kind::Symbol[value]
      end

      def activemodel_validation_errors_failure
        return @activemodel_validation_errors_failure if defined?(@activemodel_validation_errors_failure)

        @activemodel_validation_errors_failure = :invalid_attributes
      end

      def notifications=(value)
        enabled = Kind::Boolean[value]

        raise ::Micro::Case::Error::NotificationsUnavailable if enabled && !::Micro::Case::Result::Notifications::Available

        @notifications = enabled

        ::Micro::Case::Result::Notifications.enabled = enabled
      end

      def notifications
        return @notifications if defined?(@notifications)

        @notifications = false
      end

      def notifications_event_name=(value)
        ::Micro::Case::Result::Notifications.event_name = Kind::String[value]
      end

      def notifications_event_name
        ::Micro::Case::Result::Notifications.event_name
      end

      DEFAULT_TRANSACTION_CLASS_CALLBACK = -> { ::ActiveRecord::Base }.freeze

      def default_transaction_class=(callable)
        ::Micro::Case.check.transaction_class_callback!(callable)

        @default_transaction_class = callable
      end

      def default_transaction_class(&block)
        return self.default_transaction_class = block if block

        return @default_transaction_class if defined?(@default_transaction_class)

        DEFAULT_TRANSACTION_CLASS_CALLBACK
      end
    end
  end
end
