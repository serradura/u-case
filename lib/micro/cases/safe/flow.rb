# frozen_string_literal: true

module Micro
  module Cases
    module Safe
      class Flow < Cases::Flow
        private def next_use_case_result(use_case, result, input)
          instance = use_case.__new__(result, input)
          instance.call
        rescue => exception
          raise exception if Case::Error.by_wrong_usage?(exception)

          result.__set__(false, exception, :exception, instance)
        end
      end
    end
  end
end
