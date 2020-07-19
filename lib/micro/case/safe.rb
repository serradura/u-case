# frozen_string_literal: true

module Micro
  class Case
    class Safe < ::Micro::Case
      def self.__flow_builder
        Cases::Safe::Flow
      end

      def call
        __call
      rescue => exception
        raise exception if Error::ByWrongUsage.check(exception)

        Failure(result: exception)
      end
    end
  end
end
