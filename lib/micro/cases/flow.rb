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

        first_result = first_use_case_result(arg)

        return first_result if @next_use_cases.empty?

        next_use_cases_result(first_result, memo)
      end

      def to_proc
        Proc.new { |arg| call(arg) }
      end

      private

        def is_a_result?(arg)
          arg.is_a?(Case::Result)
        end

        def arg_to_call?(arg)
          return true if arg.is_a?(::Micro::Case) || arg.is_a?(Flow)
          return true if arg.is_a?(Class) && arg < ::Micro::Case
          return false
        end

        def call_arg(arg)
          output = arg.call

          is_a_result?(output) ? output.value : output
        end

        def first_use_case_input(arg)
          return call_arg(arg) if arg_to_call?(arg)
          return arg.value if is_a_result?(arg)

          arg
        end

        def first_use_case_result(arg)
          input = first_use_case_input(arg)

          result = Case::Result.new

          @first_use_case.__call_and_set_transition__(result, input)
        end

        def next_use_case_result(use_case, result, input)
          use_case.__new__(result, input).call
        end

        def next_use_cases_result(first_result, memo)
          @next_use_cases.reduce(first_result) do |result, use_case|
            break result if result.failure?

            value = result.value
            input = value.is_a?(Hash) ? memo.tap { |data| data.merge!(value) } : value

            result.__set_transitions_accessible_attributes__(memo)

            next_use_case_result(use_case, result, input)
          end
        end
    end
  end
end
