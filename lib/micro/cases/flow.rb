# frozen_string_literal: true

module Micro
  module Cases
    class Flow
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end

      attr_reader :use_cases

      def self.map_use_cases(arg)
        arg.is_a?(Flow) ? arg.use_cases : Array(arg)
      end

      def self.build(args)
        use_cases = Array(args).flat_map { |arg| map_use_cases(arg) }

        raise InvalidUseCases if use_cases.any? { |klass| !(klass < ::Micro::Case) }

        new(use_cases)
      end

      def initialize(use_cases)
        @use_cases = use_cases.dup.freeze
        @next_ones = use_cases.dup
        @first = @next_ones.shift
      end

      def call!(input:, result:)
        first_result = __case_use_case(@first, result, input)

        return first_result if @next_ones.empty?

        __call_next_use_cases(first_result)
      end

      def call(input = Kind::Empty::HASH)
        call!(input: input, result: Case::Result.new)
      end

      alias __call__ call

      def to_proc
        Proc.new { |arg| call(arg) }
      end

      def then(use_case = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise Error::InvalidInvocationOfTheThenMethod.new(self.class.name) if use_case
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !use_case && can_yield_self

          self.call.then(use_case)
        end
      end

      private

        def __case_use_case(use_case, result, input)
          use_case.__new__(result, input).__call__
        end

        def __call_next_use_cases(first_result)
          @next_ones.reduce(first_result) do |result, use_case|
            break result if result.failure?

            __case_use_case(use_case, result, result.data)
          end
        end
    end
  end
end
