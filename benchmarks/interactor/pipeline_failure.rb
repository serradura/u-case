require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.11.0'
end

require 'benchmark/ips'

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

NUMBERS = {numbers: %w[1 1 2 2 c 4]}

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Pipeline of Micro::Service::Base') do
    MSB::Add2ToAllNumbers.call(NUMBERS)
  end

  x.report('Pipeline of Micro::Service::Strict') do
    MSS::Add2ToAllNumbers.call(NUMBERS)
  end

  x.report('Interactor::Organizer') do
    IT::Add2ToAllNumbers.call(NUMBERS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Pipeline of Micro::Service::Base
#                          5.437k i/100ms
# Pipeline of Micro::Service::Strict
#                          5.192k i/100ms
# Interactor::Organizer
#                          2.236k i/100ms
# Calculating -------------------------------------
# Pipeline of Micro::Service::Base
#                          56.665k (± 1.9%) i/s -    288.161k in   5.087185s
# Pipeline of Micro::Service::Strict
#                          52.914k (± 2.0%) i/s -    264.792k in   5.006157s
# Interactor::Organizer
#                          22.940k (± 2.9%) i/s -    116.272k in   5.072931s

# Comparison:
# Pipeline of Micro::Service::Base:   56665.3 i/s
# Pipeline of Micro::Service::Strict: 52914.3 i/s - 1.07x  slower
# Interactor::Organizer:              22940.3 i/s - 2.47x  slower
