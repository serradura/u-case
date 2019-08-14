require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.12.0'
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
  class ConvertToNumbers < Micro::Service::Base
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure(numbers: 'must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Service::Base
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  Add2ToAllNumbers = ConvertToNumbers >> Add2
end

module MSS
  class ConvertToNumbers < Micro::Service::Strict
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure(numbers: 'must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Service::Strict
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

  x.report('Pipeline of Micro::Service::Base') do
    MSB::Add2ToAllNumbers.call(NUMBERS)
  end

  x.report('Pipeline of Micro::Service::Strict') do
    MSS::Add2ToAllNumbers.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Interactor::Organizer
#                          2.355k i/100ms
# Pipeline of Micro::Service::Base
#                         15.483k i/100ms
# Pipeline of Micro::Service::Strict
#                         13.467k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer
#                          23.767k (± 2.1%) i/s -    120.105k in   5.055726s
# Pipeline of Micro::Service::Base
#                         166.013k (± 1.8%) i/s -    836.082k in   5.037938s
# Pipeline of Micro::Service::Strict
#                         141.545k (± 2.1%) i/s -    713.751k in   5.044932s

# Comparison:
# Pipeline of Micro::Service::Base:   166013.1 i/s
# Pipeline of Micro::Service::Strict: 141545.4 i/s - 1.17x  slower
# Interactor::Organizer:              23766.6 i/s - 6.99x  slower
