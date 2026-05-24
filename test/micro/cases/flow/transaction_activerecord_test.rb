require 'test_helper'

if Gem.loaded_specs.key?('activerecord')
  require 'active_record'
  require 'sqlite3'

  ActiveRecord::Base.establish_connection(
    host: 'localhost',
    adapter: 'sqlite3',
    database: ':memory:'
  )

  ActiveRecord::Schema.define do
    create_table :flow_transaction_widgets, force: true do |t|
      t.column :name, :string
    end
  end

  class Micro::Cases::Flow::TransactionActiverecordTest < Minitest::Test
    class Widget < ActiveRecord::Base
      self.table_name = 'flow_transaction_widgets'
    end

    class CreateWidget < Micro::Case
      attribute :name
      def call!
        widget = Widget.create!(name: name)
        Success result: { widget: widget }
      end
    end

    class FailAfterCreate < Micro::Case
      def call!; Failure(:boom); end
    end

    class RaiseAfterCreate < Micro::Case
      def call!; raise 'kaboom'; end
    end

    def teardown
      Widget.delete_all
    end

    def test_flow_with_transaction_commits_on_success
      flow = Micro::Cases.flow(transaction: true, steps: [CreateWidget])

      result = flow.call(name: 'A')

      assert_predicate(result, :success?)
      assert_equal(1, Widget.count)
    end

    def test_flow_with_transaction_rolls_back_on_failure
      flow = Micro::Cases.flow(transaction: true, steps: [CreateWidget, FailAfterCreate])

      result = flow.call(name: 'B')

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end

    def test_flow_without_transaction_does_not_rollback
      flow = Micro::Cases.flow(steps: [CreateWidget, FailAfterCreate])

      result = flow.call(name: 'C')

      assert_predicate(result, :failure?)
      assert_equal(1, Widget.count)
    end

    def test_safe_flow_with_transaction_rolls_back_on_exception
      flow = Micro::Cases.safe_flow(transaction: true, steps: [CreateWidget, RaiseAfterCreate])

      result = flow.call(name: 'D')

      assert_predicate(result, :failure?)
      assert_equal(:exception, result.type)
      assert_equal(0, Widget.count)
    end

    def test_class_level_flow_with_transaction
      klass = Class.new(Micro::Case) do
        flow(transaction: true, steps: [CreateWidget, FailAfterCreate])
      end

      result = klass.call(name: 'E')

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end

    class InnerTxFlow < Micro::Case
      flow(transaction: true, steps: [CreateWidget, FailAfterCreate])
    end

    def test_nested_transaction_flow_inside_outer_flow_via_class
      outer = Micro::Cases.flow([InnerTxFlow])

      result = outer.call(name: 'F')

      assert_predicate(result, :failure?)
      assert_equal(0, Widget.count)
    end
  end
end
