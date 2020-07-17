# frozen_string_literal: true

require 'micro/cases/flow'
require 'micro/cases/safe/flow'

module Micro
  module Cases
    def self.flow(args)
      Flow.build(args)
    end

    def self.safe_flow(args)
      Safe::Flow.build(args)
    end
  end
end
