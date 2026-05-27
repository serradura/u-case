# frozen_string_literal: true

module Micro
  class Case
    class Result
      module Notifications
        Available = defined?(::ActiveSupport::Notifications) == 'constant'

        DEFAULT_EVENT_NAME = 'transition.micro_case'.freeze

        @enabled = false
        @event_name = DEFAULT_EVENT_NAME

        class << self
          attr_accessor :enabled
          attr_accessor :event_name
        end

        if Available
          def self.publish(result, use_case_attributes)
            return unless @enabled

            ::ActiveSupport::Notifications.instrument(@event_name,
              use_case_class:        result.use_case.class,
              attributes:            use_case_attributes,
              result_type:           result.type,
              result_kind:           result.to_sym,
              result_data:           result.data,
              accessible_attributes: result.accessible_attributes
            )
          end
        else
          def self.publish(_result, _use_case_attributes); end
        end
      end
    end
  end
end
