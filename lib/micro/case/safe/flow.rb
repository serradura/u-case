# frozen_string_literal: true

module Micro
  class Case
    class Safe
      module Flow
        def self.included(base)
          base.send(:include, ::Micro::Case::Flow)

          def base.flow_reducer; Reducer; end
        end

        class Reducer < ::Micro::Case::Flow::Reducer
          def call(arg = {})
            @use_cases.reduce(initial_result(arg)) do |result, use_case|
              break result if result.failure?

              use_case_result(use_case, result)
            end
          end

          alias_method :&, :>>

          def >>(arg)
            raise NoMethodError, "undefined method `>>' for #{self.inspect}. Please, use the method `&' to avoid this error."
          end

          private

            def use_case_result(use_case, result)
              begin
                instance = use_case.__new__(result, result.value)
                instance.call
              rescue => exception
                raise exception if Error::ByWrongUsage.check(exception)

                result.__set__(false, exception, :exception, instance)
              end
            end
        end
      end

      def self.Flow(args)
        Flow::Reducer.build(Array(args))
      end
    end
  end
end
