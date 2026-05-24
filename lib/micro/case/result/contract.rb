# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Contract
        attr_reader :successes, :failures

        def self.define(&block)
          contract = new
          block.call(Definition.new(contract))
          contract
        end

        def initialize
          @successes = {}
          @failures = {}
        end

        def add_success(type, keys)
          @successes[type] = Array(keys).map(&:to_sym)
        end

        def add_failure(type, keys)
          @failures[type] = Array(keys).map(&:to_sym)
        end

        def success_declared?(type)
          @successes.key?(type)
        end

        def failure_declared?(type)
          @failures.key?(type)
        end

        def success_keys(type)
          @successes[type]
        end

        def failure_keys(type)
          @failures[type]
        end

        class Definition
          def initialize(contract)
            @contract = contract
          end

          def success(type = :ok, result: nil)
            @contract.add_success(Kind::Symbol[type], result)
          end

          def failure(type = :error, result: nil)
            @contract.add_failure(Kind::Symbol[type], result)
          end
        end
      end
    end
  end
end
