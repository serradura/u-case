# frozen_string_literal: true

# Side-effecting leaf steps used by the transaction composition matrix tests.
#
# Each step appends its identifier to a shared :log array, increments a
# shared :counter, AND inserts a row into the `tx_widgets` table. The
# AR side-effect is the part that gets rolled back when a step in a
# `transaction: true` flow returns a Failure (or raises, under a safe
# wrapper). The accumulated `:log` / `:counter` / `*_marker` keys mirror
# the non-tx CompositionSteps so we can assert that the **observable
# result data is identical to a regular flow** — the transaction kwarg
# only affects the side-effects, never the result accumulation or the
# transitions.
module TransactionSteps
  class Widget < ActiveRecord::Base
    self.table_name = 'tx_widgets'
  end

  class A < Micro::Case
    attributes :log, :counter

    def call!
      Widget.create!(name: 'A')

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
      Widget.create!(name: 'B')

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
      Widget.create!(name: 'C')

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
      Widget.create!(name: 'D')

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
      Widget.create!(name: 'E')

      Success result: {
        log: log + ['E'],
        counter: counter + 1,
        e_marker: 'E'
      }
    end
  end

  class Fail < Micro::Case
    attributes :log, :counter

    def call!
      Widget.create!(name: 'Fail')

      Failure :step_failed, result: {
        log: log + ['Fail'],
        counter: counter + 1,
        reason: 'forced failure'
      }
    end
  end

  class BoomError < StandardError; end

  class Boom < Micro::Case
    attributes :log, :counter

    def call!
      Widget.create!(name: 'Boom')

      raise BoomError, 'boom!'
    end
  end

  INPUT = { log: [], counter: 0 }.freeze

  # Non-transactional wrappers — same shape as the composition matrix.
  NON_TX_WRAPPERS = {
    cases_flow:      ->(steps) { Micro::Cases.flow(steps) },
    cases_safe_flow: ->(steps) { Micro::Cases.safe_flow(steps) },
    class_flow:      ->(steps) { Class.new(Micro::Case)       { flow(steps) } },
    safe_class_flow: ->(steps) { Class.new(Micro::Case::Safe) { flow(steps) } }
  }.freeze

  # Transactional twins. The names mirror NON_TX_WRAPPERS so the matrix
  # combinations are easy to read.
  TX_WRAPPERS = {
    cases_flow_tx:      ->(steps) { Micro::Cases.flow(transaction: true, steps: steps) },
    cases_safe_flow_tx: ->(steps) { Micro::Cases.safe_flow(transaction: true, steps: steps) },
    class_flow_tx:      ->(steps) {
      collected = steps
      Class.new(Micro::Case) { flow(transaction: true, steps: collected) }
    },
    safe_class_flow_tx: ->(steps) {
      collected = steps
      Class.new(Micro::Case::Safe) { flow(transaction: true, steps: collected) }
    }
  }.freeze

  ALL_WRAPPERS = NON_TX_WRAPPERS.merge(TX_WRAPPERS).freeze

  # Wrappers whose chain rescues exceptions raised inside steps.
  SAFE_WRAPPER_NAMES = %i[
    cases_safe_flow cases_safe_flow_tx
    safe_class_flow safe_class_flow_tx
  ].freeze

  # Wrappers that engage ActiveRecord::Base.transaction at this level.
  TX_WRAPPER_NAMES = TX_WRAPPERS.keys.freeze
end
