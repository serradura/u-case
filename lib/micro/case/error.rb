# frozen_string_literal: true

module Micro
  class Case
    module Error
      class UnexpectedResult < TypeError
        MESSAGE = 'must return an instance of Micro::Case::Result'.freeze

        def initialize(context)
          super("#{context} #{MESSAGE}")
        end
      end

      class ResultIsAlreadyDefined < ArgumentError
        def initialize; super('result is already defined'.freeze); end
      end

      class InvalidResultType < TypeError
        def initialize; super('type must be a Symbol'.freeze); end
      end

      class InvalidResult < TypeError
        def initialize(is_success, type, use_case)
          base =
            "The result returned from #{use_case.class.name}#call! must be a Hash."

          result = is_success ? 'Success'.freeze : 'Failure'.freeze

          example =
            if type === :ok || type === :error || type === :exception
              "#{result}(result: { key: 'value' })"
            else
              "#{result}(:#{type}, result: { key: 'value' })"
            end

          super("#{base}\n\nExample:\n  #{example}")
        end
      end

      class InvalidResultInstance < ArgumentError
        def initialize; super('argument must be an instance of Micro::Case::Result'.freeze); end
      end

      class InvalidUseCase < TypeError
        def initialize; super('use case must be a kind or an instance of Micro::Case'.freeze); end
      end

      class InvalidInvocationOfTheThenMethod < StandardError
        def initialize(class_name)
          super("Invalid invocation of the #{class_name}then method")
        end
      end

      class SafeFeaturesDisabled < StandardError
        def initialize(context)
          super(
            "#{context} can't be used because the safe features are disabled. " \
            "To re-enable them, set `config.disable_safe_features = false`."
          )
        end
      end

      class UnexpectedResultType < TypeError
        def initialize(use_case_class, kind, type, declared_types)
          declared_list = declared_types.map { |t| ":#{t}" }.join(', ')
          declared_list = '(none)' if declared_list.empty?

          super(
            "#{use_case_class.name} declared a results contract — " \
            "#{kind} type :#{type} is not declared. Declared #{kind} types: #{declared_list}."
          )
        end
      end

      class MissingResultKeys < ArgumentError
        def initialize(use_case_class, kind, type, missing_keys)
          missing_list = missing_keys.map { |k| ":#{k}" }.join(', ')

          super(
            "#{use_case_class.name} declared a results contract — " \
            "#{kind} :#{type} is missing required result keys: #{missing_list}."
          )
        end
      end

      def self.by_wrong_usage?(exception)
        case exception
        when Kind::Error, ArgumentError, InvalidResult, UnexpectedResult, UnexpectedResultType then true
        else false
        end
      end
    end
  end
end
