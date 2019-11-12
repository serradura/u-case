# frozen_string_literal: true

module Micro
  class Case
    class Strict < ::Micro::Case
      include Micro::Attributes::Features::StrictInitialize

      class Safe < ::Micro::Case::Safe
        include Micro::Attributes::Features::StrictInitialize
      end
    end
  end
end
