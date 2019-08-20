require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.14.0'
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

NUMBERS = {numbers: %w[1 1 2 2 3 4]}

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
#                          4.397k i/100ms
# Pipeline of Micro::Service::Base
#                          7.153k i/100ms
# Pipeline of Micro::Service::Strict
#                          5.751k i/100ms
# Calculating -------------------------------------
# Interactor::Organizer
#                          48.942k (± 5.8%) i/s -    246.232k in   5.049100s
# Pipeline of Micro::Service::Base
#                          80.373k (± 1.7%) i/s -    407.721k in   5.074289s
# Pipeline of Micro::Service::Strict
#                          66.199k (± 2.8%) i/s -    333.558k in   5.043235s

# Comparison:
# Pipeline of Micro::Service::Base:    80373.0 i/s
# Pipeline of Micro::Service::Strict:  66198.7 i/s - 1.21x  slower
# Interactor::Organizer:               48941.9 i/s - 1.64x  slower
