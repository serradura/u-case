# frozen_string_literal: true

module Micro
  module Cases
    class Map
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end

      ValidArgs = -> (args) do
        Kind.of(Array, args).all? do |arg|
          if arg.is_a?(Array)
            arg.size == 2 && Kind.is.Micro::Case(arg.first) && arg.last.is_a?(Hash)
          else
            Kind.is.Micro::Case(arg)
          end
        end
      end

      attr_reader :use_cases

      private_constant :ValidArgs

      def self.build(args)
        raise InvalidUseCases unless ValidArgs[args]

        new(args)
      end

      def initialize(use_cases)
        @use_cases = use_cases
      end

      def call(arg = {})
        hash_arg = Kind.of(Hash, arg)

        use_cases.map do |use_case|
          if use_case.is_a?(Array)
            use_case.first.call(hash_arg.merge(use_case.last))
          else
            use_case.call(hash_arg)
          end
        end
      end
    end
  end
end
