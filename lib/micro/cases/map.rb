# frozen_string_literal: true

module Micro
  module Cases
    class Map
      IsAUseCaseOrFlowWithDefaults = -> arg { arg.is_a?(Array) && Micro.case_or_flow?(arg[0]) && arg[1].is_a?(Hash) }
      IsAUseCaseOrFlow = -> arg { Micro.case_or_flow?(arg) || IsAUseCaseOrFlowWithDefaults[arg] }
      HasValidArgs = -> (args) { Kind::Array[args].all?(&IsAUseCaseOrFlow) }

      attr_reader :use_cases

      def self.build(args)
        raise Error::InvalidUseCases unless HasValidArgs[args]

        new(args)
      end

      def initialize(use_cases)
        @use_cases = use_cases
      end

      GetUseCaseResult = -> (hash) do
        -> (use_case) do
          return use_case.call(hash) unless use_case.is_a?(Array)

          use_case[0].call(hash.merge(use_case[1]))
        end
      end

      def call(arg = {})
        hash = Kind::Hash[arg]

        use_cases.map(&GetUseCaseResult[hash])
      end

      private_constant :HasValidArgs, :IsAUseCaseOrFlow, :IsAUseCaseOrFlowWithDefaults, :GetUseCaseResult
    end
  end
end
