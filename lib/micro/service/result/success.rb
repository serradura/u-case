# frozen_string_literal: true

module Micro
  module Service
    class Result
      class Success < Micro::Service::Result
        def success?; true; end
      end
    end
  end
end
