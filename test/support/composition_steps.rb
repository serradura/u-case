# frozen_string_literal: true

# Leaf use cases used by the flow composition matrix tests.
#
# Each step appends its identifier to a shared :log array and increments a
# shared :counter. Strict subclasses require the markers produced by all
# previous steps in the canonical A -> B -> C -> D -> E chain, which forces
# the flow machinery to keep the accumulated state visible to every step
# regardless of how deep the composition is nested.
module CompositionSteps
  class A < Micro::Case
    attributes :log, :counter

    def call!
      Success result: {
        log: log + ['A'],
        counter: counter + 1,
        a_marker: 'A'
      }
    end
  end

  class B < Micro::Case::Strict
    attributes :log, :counter, :a_marker

    def call!
      Success result: {
        log: log + ['B'],
        counter: counter + 1,
        b_marker: 'B'
      }
    end
  end

  class C < Micro::Case::Safe
    attributes :log, :counter, :a_marker, :b_marker

    def call!
      Success result: {
        log: log + ['C'],
        counter: counter + 1,
        c_marker: 'C'
      }
    end
  end

  class D < Micro::Case::Strict::Safe
    attributes :log, :counter, :a_marker, :b_marker, :c_marker

    def call!
      Success result: {
        log: log + ['D'],
        counter: counter + 1,
        d_marker: 'D'
      }
    end
  end

  class E < Micro::Case::Strict
    attributes :log, :counter, :a_marker, :b_marker, :c_marker, :d_marker

    def call!
      Success result: {
        log: log + ['E'],
        counter: counter + 1,
        e_marker: 'E'
      }
    end
  end

  # Always fails with a known type.
  class Fail < Micro::Case
    attributes :log, :counter

    def call!
      Failure :step_failed, result: {
        log: log + ['Fail'],
        counter: counter + 1,
        reason: 'forced failure'
      }
    end
  end

  # Custom exception so it isn't classified as "wrong usage" by
  # Micro::Case::Error.by_wrong_usage? (ArgumentError, Kind::Error,
  # InvalidResult and UnexpectedResult are intentionally re-raised even
  # inside Safe wrappers).
  class BoomError < StandardError; end

  # Raises an exception; only Safe wrappers can rescue it.
  class Boom < Micro::Case
    attributes :log, :counter

    def call!
      raise BoomError, 'boom!'
    end
  end

  INPUT = { log: [], counter: 0 }.freeze

  WRAPPERS = {
    cases_flow:      ->(steps) { Micro::Cases.flow(steps) },
    cases_safe_flow: ->(steps) { Micro::Cases.safe_flow(steps) },
    class_flow:      ->(steps) {
      Class.new(Micro::Case) { flow(steps) }
    },
    safe_class_flow: ->(steps) {
      Class.new(Micro::Case::Safe) { flow(steps) }
    }
  }.freeze
end
