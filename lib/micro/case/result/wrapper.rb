# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Wrapper
        def initialize(result)
          @result = result
        end

        def failure(type = nil)
          return if @result.success?

          return yield(@result) if result_type?(type)
        end

        def success(type = nil)
          return if @result.failure?

          return yield(@result) if result_type?(type)
        end

        private

          def result_type?(type)
            type.nil? || @result.type == type
          end
      end
    end
  end
end
