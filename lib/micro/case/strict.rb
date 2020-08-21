# frozen_string_literal: true

module Micro
  class Case
    class Strict < ::Micro::Case
      include Micro::Attributes::Features::Initialize::Strict

      class Safe < ::Micro::Case::Safe
        include Micro::Attributes::Features::Initialize::Strict
      end
    end
  end
end
