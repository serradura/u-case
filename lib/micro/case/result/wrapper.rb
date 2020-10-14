# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Wrapper
        def initialize(result)
          @__is_unknown = true

          @result = result
        end

        def failure(type = nil)
          return if @result.success?

          if result_type?(type)
            @__is_unknown = false

            yield(@result)
          end
        end

        def success(type = nil)
          return if @result.failure?

          if result_type?(type)
            @__is_unknown = false

            yield(@result)
          end
        end

        def unknown
          return yield(@result) if @__is_unknown
        end

        private

          def result_type?(type)
            type.nil? || @result.type == type
          end
      end
    end
  end
end
