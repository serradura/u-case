# frozen_string_literal: true

module Micro
  module Cases

    module Error
      class InvalidUseCases < ArgumentError
        def initialize; super('argument must be a collection of `Micro::Case` classes'.freeze); end
      end
    end

  end
end
