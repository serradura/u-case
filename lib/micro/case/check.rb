# frozen_string_literal: true

module Micro
  class Case
    module Check
      module Enabled
        extend self

        def use_case_or_flow!(arg)
          raise Error::InvalidUseCase unless ::Micro.case_or_flow?(arg)
        end

        def micro_case_instance!(arg)
          raise Error::InvalidUseCase unless arg.is_a?(::Micro::Case)
        end

        def result_instance!(arg)
          raise Error::InvalidResultInstance unless arg.is_a?(::Micro::Case::Result)
        end

        def result_not_defined!(is_defined)
          raise Error::ResultIsAlreadyDefined if is_defined
        end

        def result_type!(type)
          raise Error::InvalidResultType unless type.is_a?(Symbol)
        end

        def result_data!(data, is_success, type, use_case)
          raise Error::InvalidResult.new(is_success, type, use_case) unless data
        end

        def expected_result!(result, context)
          return if result.is_a?(::Micro::Case::Result)

          raise Error::UnexpectedResult.new(context)
        end

        def expected_self_result!(actual, expected, context)
          return if actual.equal?(expected)

          raise Error::UnexpectedResult.new(context)
        end

        def then_use_case_or_flow!(arg, owner_label)
          return if ::Micro.case_or_flow?(arg)

          raise Error::InvalidInvocationOfTheThenMethod.new(owner_label)
        end

        def flow_use_cases!(use_cases)
          raise Cases::Error::InvalidUseCases if use_cases.none?(&::Micro::Cases::Flow::IsAValidUseCase)
        end

        def map_args!(args)
          raise Cases::Error::InvalidUseCases unless ::Micro::Cases::Map.const_get(:HasValidArgs, false)[args]
        end

        def hash!(arg)
          Kind::Hash[arg]
        end

        def flow_steps_kwarg!(args, steps, label)
          return unless args && steps

          raise ArgumentError,
            "#{label} accepts a positional collection OR `steps:`, not both"
        end

        def transaction_kwarg!(value)
          return nil if value.nil? || value == false
          return true if value == true

          if value.is_a?(Class)
            transaction_owner!(value)
            return value
          end

          if value.is_a?(Hash)
            extra = value.keys - [:with]

            raise ArgumentError,
              "transaction: unsupported key(s) #{extra.inspect} (only `:with` is accepted)" unless extra.empty?

            with = value[:with]
            transaction_owner!(with)

            return with
          end

          raise ArgumentError,
            "transaction: #{value.inspect} is not supported (accepts `true`, `false`, `nil`, or `{ with: SomeARClass }`)"
        end

        def activerecord_loaded!
          return if defined?(::ActiveRecord::Base)

          raise ::Micro::Cases::Error::TransactionAdapterMissing
        end

        # Validates a transaction owner class. We accept Class instances
        # only; the AR-subclass check is enforced if (and only if)
        # ActiveRecord is already loaded — otherwise we defer to runtime
        # so that load-order quirks (Rails initializers running before
        # the AR autoload) don't break class-eval-time declarations.
        def transaction_owner!(klass)
          raise ArgumentError,
            "transaction owner #{klass.inspect} must be a subclass of ActiveRecord::Base" unless klass.is_a?(Class)

          return unless defined?(::ActiveRecord::Base)
          return if klass <= ::ActiveRecord::Base

          raise ArgumentError,
            "transaction owner #{klass.inspect} must be a subclass of ActiveRecord::Base"
        end

        def transaction_class_callback!(callable)
          return if callable.respond_to?(:call)

          raise ArgumentError,
            "Micro::Case.config.default_transaction_class= expects a callable (a block, lambda or proc), got #{callable.inspect}"
        end

        def results_contract!(use_case_class, kind, type, value)
          contract = use_case_class.__results_contract__
          return unless contract
          return unless type.is_a?(Symbol)
          return if value.is_a?(Exception)

          if kind == :success
            declared = contract.success_declared?(type)
            declared_types = contract.successes.keys
            required = contract.success_keys(type) if declared
          else
            declared = contract.failure_declared?(type)
            declared_types = contract.failures.keys
            required = contract.failure_keys(type) if declared
          end

          raise Error::UnexpectedResultType.new(use_case_class, kind, type, declared_types) unless declared
          return if required.nil? || required.empty?

          if value.is_a?(Hash)
            data_keys = value.keys.map { |k| k.is_a?(String) ? k.to_sym : k }
          elsif value.is_a?(Symbol)
            data_keys = [type]
          else
            return
          end

          missing = required - data_keys

          raise Error::MissingResultKeys.new(use_case_class, kind, type, missing) unless missing.empty?
        end
      end

      module Disabled
        extend self

        def use_case_or_flow!(_arg); end
        def micro_case_instance!(_arg); end
        def result_instance!(_arg); end
        def result_not_defined!(_is_defined); end
        def result_type!(_type); end
        def result_data!(_data, _is_success, _type, _use_case); end
        def expected_result!(_result, _context); end
        def expected_self_result!(_actual, _expected, _context); end
        def then_use_case_or_flow!(_arg, _owner_label); end
        def flow_use_cases!(_use_cases); end
        def map_args!(_args); end
        def hash!(arg); arg; end
        def flow_steps_kwarg!(_args, _steps, _label); end
        def transaction_kwarg!(value)
          return true if value == true
          return value if value.is_a?(Class)
          return value[:with] if value.is_a?(Hash) && value[:with].is_a?(Class)
          nil
        end
        def activerecord_loaded!; end
        def transaction_owner!(_klass); end
        def transaction_class_callback!(_callable); end
        def results_contract!(_use_case_class, _kind, _type, _value); end
      end
    end
  end
end
