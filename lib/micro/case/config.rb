# frozen_string_literal: true

require 'singleton'

module Micro
  class Case
    class Config
      include Singleton

      def enable_activemodel_validation=(value)
        return unless Kind::Of::Boolean(value)

        require 'micro/case/with_activemodel_validation'
      end

      def enable_transitions=(value)
        Micro::Case::Result.class_variable_set(
          :@@transition_tracking_enabled, Kind::Of::Boolean(value)
        )
      end
    end
  end
end
