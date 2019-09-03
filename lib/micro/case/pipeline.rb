# frozen_string_literal: true

module Micro
  module Case
    module Pipeline
      module ClassMethods
        def __pipeline__
          @__pipeline
        end

        def pipeline(*args)
          @__pipeline = pipeline_reducer.build(args)
        end

        def call(options = {})
          new(options).call
        end
      end

      CONSTRUCTOR = <<-RUBY
      def initialize(options)
        @options = options
        pipeline = self.class.__pipeline__
        raise Error::UndefinedPipeline unless pipeline
      end
      RUBY

      private_constant :ClassMethods, :CONSTRUCTOR

      def self.included(base)
        def base.pipeline_reducer; Reducer; end
        base.extend(ClassMethods)
        base.class_eval(CONSTRUCTOR)
      end

      def self.[](*args)
        Reducer.build(args)
      end

      def call
        self.class.__pipeline__.call(@options)
      end

      module Safe
        def self.included(base)
          base.send(:include, Micro::Case::Pipeline)
          def base.pipeline_reducer; SafeReducer; end
        end

        def self.[](*args)
          SafeReducer.build(args)
        end
      end
    end
  end
end
