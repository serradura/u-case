# frozen_string_literal: true

require 'micro/cases/utils'
require 'micro/cases/error'
require 'micro/cases/flow'
require 'micro/cases/safe/flow'
require 'micro/cases/map'

module Micro
  module Cases
    def self.flow(args = nil, transaction: nil, steps: nil)
      Flow.build(__flow_steps(args, steps, 'Micro::Cases.flow'), transaction: transaction)
    end

    def self.safe_flow(args = nil, transaction: nil, steps: nil)
      if Case::Config.instance.disable_safe_features
        raise Case::Error::SafeFeaturesDisabled.new('Micro::Cases.safe_flow')
      end

      Safe::Flow.build(__flow_steps(args, steps, 'Micro::Cases.safe_flow'), transaction: transaction)
    end

    def self.map(args)
      Map.build(args)
    end

    def self.__flow_steps(args, steps, method)
      return args if steps.nil?

      raise ArgumentError, "#{method} accepts a positional collection OR `steps:`, not both" if args
      steps
    end

    private_class_method :__flow_steps
  end
end
