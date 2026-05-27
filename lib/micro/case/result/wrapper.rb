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

        def failure(*types, &block)
          return if @result.success? || !undefined_output?

          set_output(call_block(block)) if result_type?(types)
        end

        def success(*types, &block)
          return if @result.failure? || !undefined_output?

          set_output(call_block(block)) if result_type?(types)
        end

        def unknown(&block)
          @output = call_block(block) if @__is_unknown && undefined_output?
        end

        private

          def call_block(block)
            if block.arity == 2
              block.call(@result.data, @result.type)
            else
              block.call(@result)
            end
          end

          def set_output(value)
            @__is_unknown = false

            @output = value
          end

          def undefined_output?
            ::Kind::Undefined == @output
          end

          def result_type?(types)
            types.empty? || types.any?(@result.type)
          end
      end
    end
  end
end
