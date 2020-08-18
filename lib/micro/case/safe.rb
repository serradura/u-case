# frozen_string_literal: true

module Micro
  class Case
    class Safe < ::Micro::Case
      def self.__flow_builder__
        Cases::Safe::Flow
      end

      def __call__
        call
      rescue => exception
        raise exception if Error.by_wrong_usage?(exception)

        Failure(result: exception)
      end
    end
  end
end
