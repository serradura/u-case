# frozen_string_literal: true

module AddFiveWith
  module MicroCase
    module Flow

      module UsingResultThens
        def self.call(params)
          ConvertTextToNumber
            .call(params)
            .then(Add1)
            .then(Add1)
            .then(Add1)
            .then(Add1)
            .then(Add1)
        end
      end

    end
  end
end
