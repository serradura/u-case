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
          alias_method :&, :>>

          def >>(arg)
            raise NoMethodError, "undefined method `>>' for #{self.inspect}. Please, use the method `&' to avoid this error."
          end

          private

            def use_case_result(use_case, result, input)
              begin
                instance = use_case.__new__(result, input)
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

      def self.flow(*args)
        @__flow ||= __set_flow__(Flow::Reducer, args)
      end
    end
  end
end
