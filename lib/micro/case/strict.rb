# frozen_string_literal: true

module Micro
  module Case
    class Strict < Case::Base
      include Micro::Attributes::Features::StrictInitialize

      class Safe < Case::Safe
        include Micro::Attributes::Features::StrictInitialize
      end
    end
  end
end
