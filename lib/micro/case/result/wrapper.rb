# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Wrapper
        attr_reader :output

        def initialize(result)
          @result = result
          @output = ::Kind::Undefined

          @__is_unknown = true
        end

        def failure(type = nil)
          return if @result.success? || !undefined_output?

          set_output(yield(@result)) if result_type?(type)
        end

        def success(type = nil)
          return if @result.failure? || !undefined_output?

          set_output(yield(@result)) if result_type?(type)
        end

        def unknown
          @output = yield(@result) if @__is_unknown && undefined_output?
        end

        private

          def set_output(value)
            @__is_unknown = false

            @output = value
          end

          def undefined_output?
            ::Kind::Undefined == @output
          end

          def result_type?(type)
            type.nil? || @result.type == type
          end
      end
    end
  end
end
