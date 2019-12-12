# frozen_string_literal: true

module Micro
  class Case
    module Flow
      module ClassMethods
        def __flow__
          @__flow
        end

        def flow(*args)
          @__flow = flow_reducer.build(args)
        end

        def call(options = {})
          new(options).call
        end
      end

      CONSTRUCTOR = <<-RUBY
      def initialize(options)
        @options = options

        flow = self.class.__flow__

        raise Error::UndefinedFlow unless flow
      end
      RUBY

      private_constant :ClassMethods, :CONSTRUCTOR

      # Deprecated: Classes with flows are now defined via `Micro::Case` inheritance
      def self.included(base)
        warn 'Deprecation: Micro::Case::Flow mixin is being deprecated, please use `Micro::Case` inheritance instead.'

        def base.flow_reducer; Reducer; end

        base.extend(ClassMethods)

        base.class_eval(CONSTRUCTOR)
      end

      def call
        self.class.__flow__.call(@options)
      end
    end
  end
end
