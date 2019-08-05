# frozen_string_literal: true

module Micro
  module Service
    module Strict
      class Base < Service::Base
        include Micro::Attributes::Features::StrictInitialize
      end
    end
  end
end
