# frozen_string_literal: true

require 'micro/cases/utils'
require 'micro/cases/error'
require 'micro/cases/flow'
require 'micro/cases/safe/flow'
require 'micro/cases/map'

module Micro
  module Cases
    def self.flow(args = nil, transaction: nil, steps: nil)
      ::Micro::Case.check.flow_steps_kwarg!(args, steps, 'Micro::Cases.flow')

      Flow.build(steps || args, transaction: transaction)
    end

    def self.safe_flow(args = nil, transaction: nil, steps: nil)
      if Case::Config.instance.disable_safe_features
        raise Case::Error::SafeFeaturesDisabled.new('Micro::Cases.safe_flow')
      end

      ::Micro::Case.check.flow_steps_kwarg!(args, steps, 'Micro::Cases.safe_flow')

      Safe::Flow.build(steps || args, transaction: transaction)
    end

    def self.map(args)
      Map.build(args)
    end
  end
end
