# frozen_string_literal: true

require 'micro/cases/utils'
require 'micro/cases/error'
require 'micro/cases/flow'
require 'micro/cases/safe/flow'
require 'micro/cases/map'

module Micro
  module Cases
    def self.flow(args)
      Flow.build(args)
    end

    def self.safe_flow(args)
      Safe::Flow.build(args)
    end

    def self.map(args)
      Map.build(args)
    end
  end
end
