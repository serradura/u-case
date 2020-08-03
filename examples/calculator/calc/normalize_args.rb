module Calc
  class NormalizeArgs < Micro::Case
    attribute :args

    def call!
      a, b = normalize(args[:a]), normalize(args[:b])

      if a !~ /\s/ && b !~ /\s/
        Success result: { a: a, b: b }
      else
        Failure :arguments_with_space_chars, result: {
          attributes: [a, b].map(&:inspect)
        }
      end
    end

    private def normalize(value)
      String(value).strip
    end
  end
end
