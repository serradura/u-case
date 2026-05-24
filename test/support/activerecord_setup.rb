# frozen_string_literal: true

# Shared ActiveRecord/SQLite setup for transaction test files.
#
# `establish_connection` swaps the global AR connection, so if every
# test file calls it independently the *second* file's call wipes the
# first file's schema. Centralizing the setup here lets multiple test
# files share one in-memory database and contribute their own tables.

require 'active_record'
require 'sqlite3'

unless defined?(::ActiveRecordTestSetup)
  module ::ActiveRecordTestSetup
    ActiveRecord::Base.establish_connection(
      host: 'localhost',
      adapter: 'sqlite3',
      database: ':memory:'
    )

    ActiveRecord::Schema.define do
      create_table :flow_transaction_widgets, force: true do |t|
        t.column :name, :string
      end

      create_table :tx_widgets, force: true do |t|
        t.column :name, :string
      end
    end
  end
end
