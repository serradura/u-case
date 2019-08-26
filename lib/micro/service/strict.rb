# frozen_string_literal: true

module Micro
  module Service
    class Strict < Service::Base
      include Micro::Attributes::Features::StrictInitialize

      class Safe < Service::Safe
        include Micro::Attributes::Features::StrictInitialize
      end
    end
  end
end
