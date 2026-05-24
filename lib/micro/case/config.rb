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
    end
  end
end
