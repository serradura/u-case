# frozen_string_literal: true

module AddFiveWith
  module Interactor

    class ConvertTextToNumber
      include ::Interactor

      def call
        text = context.text

        if text =~ /\d+/
          context.number = text.to_i
        else
          context.fail! text: 'must be an integer value'
        end
      end
    end

    class Add1
      include ::Interactor

      def call
        context.number = context.number + 1
      end
    end

    class Organizer
      include ::Interactor::Organizer

      organize(
        ConvertTextToNumber,
        Add1,
        Add1,
        Add1,
        Add1,
        Add1
      )
    end

  end
end
