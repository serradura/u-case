# frozen_string_literal: true

module Micro
  module Cases

    module Error
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end

      class TransactionAdapterMissing < RuntimeError
        def initialize
          super(
            'transaction: true requires ActiveRecord to be loaded. '\
            "Add `require 'active_record'` (or `gem 'activerecord'` to your Gemfile) before invoking the flow.".freeze
          )
        end
      end
    end

  end
end
