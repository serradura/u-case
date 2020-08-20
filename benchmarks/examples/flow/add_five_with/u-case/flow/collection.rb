# frozen_string_literal: true

module AddFiveWith
  module MicroCase
    module Flow

      Collection = Micro::Cases.flow([
        ConvertTextToNumber,
        Add1,
        Add1,
        Add1,
        Add1,
        Add1
      ])

    end
  end
end
