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
      end
    end
  end
end
