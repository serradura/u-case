# frozen_string_literal: true

module Micro
  module Cases
    class Flow
      IsAUseCaseWithDefaults = -> arg { arg.is_a?(Array) && Micro.case?(arg[0]) && arg[1].is_a?(Hash) }
      IsAValidUseCase = -> use_case { Micro.case?(use_case) || IsAUseCaseWithDefaults[use_case] }

      attr_reader :use_cases

      def self.build(args, transaction: nil)
        use_cases = Utils.map_use_cases(args)

        ::Micro::Case.check.flow_use_cases!(use_cases)

        new(use_cases, transaction: transaction)
      end

      def initialize(use_cases, transaction: nil)
        @use_cases = use_cases.dup.freeze
        @next_ones = use_cases.dup
        @first = @next_ones.shift
        @transaction = ::Micro::Case.check.transaction_kwarg!(transaction)
      end

      def inspect
        return '#<(%s) use_cases=%s>' % [self.class, @use_cases] unless @transaction

        '#<(%s) transaction=%p use_cases=%s>' % [self.class, @transaction, @use_cases]
      end

      def call!(input:, result:)
        return __call_steps(input, result) unless @transaction

        __wrap_in_transaction { __call_steps(input, result) }
      end

      def call(input = Kind::Empty::HASH)
        result = call!(input: input, result: Case::Result.new)

        return result unless block_given?

        result_wrapper = ::Micro::Case::Result::Wrapper.new(result)

        yield(result_wrapper)

        result_wrapper.output
      end

      alias __call__ call

      def to_proc
        Proc.new { |arg| call(arg) }
      end

      def then(use_case = nil, &block)
        can_yield_self = respond_to?(:yield_self)

        if block
          raise_invalid_invocation_of_the_then_method if use_case
          raise NotImplementedError if !can_yield_self

          yield_self(&block)
        else
          return yield_self if !use_case && can_yield_self

          ::Micro::Case.check.then_use_case_or_flow!(use_case, "#{self.class.name}#")

          self.call.then(use_case)
        end
      end

      private

        def raise_invalid_invocation_of_the_then_method
          raise Case::Error::InvalidInvocationOfTheThenMethod.new("#{self.class.name}#")
        end

        def __call_steps(input, result)
          first_result = __call_use_case(@first, result, input)

          return first_result if @next_ones.empty?

          __call_next_use_cases(first_result)
        end

        def __wrap_in_transaction
          owner = __transaction_owner

          result = nil

          owner.transaction do
            result = yield

            raise ::ActiveRecord::Rollback if result.failure?
          end

          result
        end

        def __transaction_owner
          return @transaction if @transaction.is_a?(Class)

          callback = ::Micro::Case::Config.instance.default_transaction_class

          # Only the gem's default callback (`-> { ActiveRecord::Base }`)
          # needs the AR-loaded guard. A user-supplied callback can
          # return whatever class they want — we trust it.
          if callback.equal?(::Micro::Case::Config::DEFAULT_TRANSACTION_CLASS_CALLBACK)
            ::Micro::Case.check.activerecord_loaded!
          end

          callback.call
        end

        def __call_use_case(use_case, result, input)
          __build_use_case(use_case, result, input).__call__
        end

        def __call_next_use_cases(first_result)
          @next_ones.reduce(first_result) do |result, use_case|
            break result if result.failure?

            __call_use_case(use_case, result, result.data)
          end
        end

        def __build_use_case(use_case, result, input)
          return use_case.__new__(result, input) unless use_case.is_a?(Array)

          use_case[0].__new__(result, input.merge(use_case[1]))
        end
    end
  end
end
