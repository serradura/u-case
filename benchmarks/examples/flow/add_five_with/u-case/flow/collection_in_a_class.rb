# frozen_string_literal: true

module AddFiveWith
  module MicroCase
    module Flow

      class CollectionInAClass < Micro::Case
        flow ConvertTextToNumber,
            Add1,
            Add1,
            Add1,
            Add1,
            Add1
      end

    end
  end
end
