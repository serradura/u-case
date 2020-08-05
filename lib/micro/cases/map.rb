# frozen_string_literal: true

module Micro
  module Cases
    class Map
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end

      attr_reader :use_cases

      def self.build(args)
        use_cases = Kind.of.Array(args)

        raise InvalidUseCases if use_cases.any? { |klass| !(klass < ::Micro::Case) }

        new(use_cases)
      end

      def initialize(use_cases)
        @use_cases = use_cases
      end

      def call(arg = {})
        hash_arg = Kind.of.Hash(arg)
        use_cases.map { |use_case| use_case.call(hash_arg) }
      end
    end
  end
end
