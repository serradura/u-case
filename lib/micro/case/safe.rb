# frozen_string_literal: true

module Micro
  class Case
    class Safe < ::Micro::Case
      def self.__flow_builder__
        Cases::Safe::Flow
      end

      def __call__
        __call_the_use_case_or_its_flow
      rescue => exception
        raise exception if Error.by_wrong_usage?(exception)

        Failure(result: exception)
      end
    end
  end
end
