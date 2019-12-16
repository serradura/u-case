# frozen_string_literal: true

module Micro
  class Case
    module Flow
      class Reducer
        attr_reader :use_cases

        def self.map_use_cases(arg)
          return arg.use_cases if arg.is_a?(Reducer)
          return arg.__flow__.use_cases if arg.is_a?(Class) && arg < ::Micro::Case::Flow

          Array(arg)
        end

        def self.build(args)
          use_cases = Array(args).flat_map { |arg| map_use_cases(arg) }

          raise Error::InvalidUseCases if use_cases.any? { |klass| !(klass < ::Micro::Case) }

          new(use_cases)
        end

        def initialize(use_cases)
          @use_cases = use_cases
        end

        def call(arg = {})
          input = arg.is_a?(Hash) ? arg.dup : {}

          @use_cases.reduce(initial_result(arg)) do |result, use_case|
            break result if result.failure?

            input.merge!(result.data)

            use_case_result(use_case, result, input)
          end
        end

        def >>(arg)
          self.class.build(use_cases + self.class.map_use_cases(arg))
        end

        def &(arg)
          raise NoMethodError, "undefined method `&' for #{self.inspect}. Please, use the method `>>' to avoid this error."
        end

        def to_proc
          Proc.new { |arg| call(arg) }
        end

        private

          def use_case_result(use_case, result, input)
            use_case.__new__(result, input).call
          end

          def initial_result(arg)
            return arg.call if arg_to_call?(arg)
            return arg if arg.is_a?(Micro::Case::Result)

            result = ::Micro::Case::Result.new
            result.__set__(true, Attributes::AttributesUtils.hash_argument!(arg), :ok, nil)
          end

          def arg_to_call?(arg)
            return true if arg.is_a?(::Micro::Case) || arg.is_a?(Reducer)
            return true if arg.is_a?(Class) && (arg < ::Micro::Case || arg < ::Micro::Case::Flow)
            return false
          end
      end
    end
  end
end
