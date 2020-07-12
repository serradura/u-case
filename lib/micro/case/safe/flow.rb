# frozen_string_literal: true

module Micro
  class Case
    class Safe
      module Flow
        class Reducer < ::Micro::Case::Flow::Reducer
          private def next_use_case_result(use_case, result, input)
            instance = use_case.__new__(result, input)
            instance.call
          rescue => exception
            raise exception if Error::ByWrongUsage.check(exception)

            result.__set__(false, exception, :exception, instance)
          end
        end
      end

      def self.Flow(args)
        Flow::Reducer.build(Array(args))
      end
    end
  end
end
