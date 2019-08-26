module Calc
  class NormalizeArgs < Micro::Service::Base
    attributes :args

    def call!
      a, b = normalize(args[:a]), normalize(args[:b])

      return Success(a: a, b: b) if a !~ /\s/ && b !~ /\s/

      Failure(:arguments_with_space_chars) { [a, b].map(&:inspect) }
    end

    private def normalize(value)
      String(value).strip
    end
  end
end
