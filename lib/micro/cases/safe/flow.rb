# frozen_string_literal: true

module Micro
  module Cases
    module Safe
      class Flow < Cases::Flow
        private def __call_use_case(use_case, result, input)
          instance = __build_use_case(use_case, result, input)
          instance.__call__
        rescue => exception
          raise exception if Case::Error.by_wrong_usage?(exception)

          result.__set__(false, exception, :exception, instance)
        end
      end
    end
  end
end
