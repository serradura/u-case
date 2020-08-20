# frozen_string_literal: true

module AddFiveWith
  module MicroCase
    module Flow

      class IncludingTheClass < Micro::Case
        flow self,
            Add1,
            Add1,
            Add1,
            Add1,
            Add1

        attribute :text

        def call!
          return Success(result: text.to_i) if text =~ /\d+/

          Failure result: { text: 'must be an integer value' }
        end
      end

    end
  end
end
