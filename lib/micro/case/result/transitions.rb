# frozen_string_literal: true

module Micro
  class Case
    class Result
      class Transitions
        MapEverything = -> (result, use_case_attributes) do
          {
            use_case: { class: result.use_case.class, attributes: use_case_attributes },
            result.to_sym => { type: result.type, result: result.data },
            accessible_attributes: result.accessible_attributes
          }
        end
      end
    end
  end
end
