# frozen_string_literal: true

module Micro
  module Cases
    class Flow
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end

      attr_reader :use_cases

      def self.map_use_cases(arg)
        return arg.use_cases if arg.is_a?(Flow)

        Array(arg)
      end

      def self.build(args)
        use_cases = Array(args).flat_map { |arg| map_use_cases(arg) }

        raise InvalidUseCases if use_cases.any? { |klass| !(klass < ::Micro::Case) }

        new(use_cases)
      end

      def initialize(use_cases)
        @use_cases = use_cases
        @first_use_case = use_cases[0]
        @next_use_cases = use_cases[1..-1]
      end

      def call(arg = {})
        memo = arg.is_a?(Hash) ? arg.dup : {}

        first_result = __first_use_case_result(arg)

        return first_result if @next_use_cases.empty?

        __next_use_cases_result(first_result, memo)
      end

      alias __call__ call

      def to_proc
        Proc.new { |arg| call(arg) }
      end

      private

        def __is_a_result?(arg)
          arg.is_a?(Case::Result)
        end

        def __call_arg(arg)
          output = arg.__call__

          __is_a_result?(output) ? output.value : output
        end

        def __first_use_case_input(arg)
          return __call_arg(arg) if ::Micro.case_or_flow?(arg)
          return arg.value if __is_a_result?(arg)

          arg
        end

        def __first_use_case_result(arg)
          input = __first_use_case_input(arg)

          result = Case::Result.new

          @first_use_case.__call_and_set_transition__(result, input)
        end

        def __next_use_case_result(use_case, result, input)
          use_case.__new__(result, input).__call__
        end

        def __next_use_cases_result(first_result, memo)
          @next_use_cases.reduce(first_result) do |result, use_case|
            break result if result.failure?

            memo.merge!(result.value)

            result.__set_transitions_accessible_attributes__(memo)

            __next_use_case_result(use_case, result, memo)
          end
        end
    end
  end
end
