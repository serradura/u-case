require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-case', '~> 1.0.0'
end

require 'benchmark/ips'

module IT
  class ConvertToNumbers
    include Interactor

    def call
      numbers = context.numbers

      if numbers.all? { |value| String(value) =~ /\d+/ }
        context.numbers = numbers.map(&:to_i)
      else
        context.fail! numbers: 'must contain only numeric types'
      end
    end
  end

  class Add2
    include Interactor

    def call
      numbers = context.numbers

      context.numbers = numbers.map { |number| number + 2 }
    end
  end

  class Add2ToAllNumbers
    include Interactor::Organizer

    organize ConvertToNumbers, Add2
  end
end

module MSB
  class ConvertToNumbers < Micro::Case::Base
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure(numbers: 'must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Base
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  Add2ToAllNumbers = ConvertToNumbers >> Add2
end

module MSS
  class ConvertToNumbers < Micro::Case::Strict
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure(numbers: 'must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  Add2ToAllNumbers = ConvertToNumbers >> Add2
end

NUMBERS = {numbers: %w[1 1 2 2 c 4]}

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Interactor::Organizer') do
    IT::Add2ToAllNumbers.call(NUMBERS)
  end

  x.report('A flow with Micro::Case::Base') do
    MSB::Add2ToAllNumbers.call(NUMBERS)
  end

  x.report('A flow with Micro::Case::Strict') do
    MSS::Add2ToAllNumbers.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Interactor::Organizer
#                          2.319k i/100ms
# A flow with Micro::Case::Base
#                         14.237k i/100ms
# A flow with Micro::Case::Strict
#                         12.301k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer
#                          23.511k (± 3.0%) i/s -    118.269k in   5.035043s
# A flow with Micro::Case::Base
#                         152.649k (± 1.7%) i/s -    768.798k in   5.037869s
# A flow with Micro::Case::Strict
#                         129.477k (± 2.7%) i/s -    651.953k in   5.039222s

# Comparison:
# A flow with Micro::Case::Base:   152648.6 i/s
# A flow with Micro::Case::Strict: 129477.0 i/s - 1.18x  slower
# Interactor::Organizer:           23511.2 i/s - 6.49x  slower
