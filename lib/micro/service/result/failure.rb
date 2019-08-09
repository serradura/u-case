# frozen_string_literal: true

module Micro
  module Service
    class Result
      class Failure < Micro::Service::Result
        def success?; false; end
      end
    end
  end
end
