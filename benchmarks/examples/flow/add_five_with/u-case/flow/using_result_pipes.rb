# frozen_string_literal: true

module AddFiveWith
  module MicroCase
    module Flow

      module UsingResultPipes
        def self.call(params)
          ConvertTextToNumber
            .call(params) \
            | Add1 \
            | Add1 \
            | Add1 \
            | Add1 \
            | Add1
        end
      end

    end
  end
end
