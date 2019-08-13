require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.11.0'
end

require 'benchmark/ips'

class MSB_Multiply < Micro::Service::Base
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure(:invalid_data)
    end
  end
end

class MSS_Multiply < Micro::Service::Strict
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure(:invalid_data)
    end
  end
end

class IT_Multiply
  include Interactor

  def call
    a = context.a
    b = context.b

    if a.is_a?(Numeric) && b.is_a?(Numeric)
      context.number = a * b
    else
      context.fail!(type: :invalid_data)
    end
  end
end

SYMBOL_KEYS = { a: nil, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => '' }

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Micro::Service::Base') do
    MSB_Multiply.call(SYMBOL_KEYS)
    MSB_Multiply.call(STRING_KEYS)
  end

  x.report('Micro::Service::Strict') do
    MSS_Multiply.call(SYMBOL_KEYS)
    MSS_Multiply.call(STRING_KEYS)
  end

  x.report('Interactor') do
    IT_Multiply.call(SYMBOL_KEYS)
    IT_Multiply.call(STRING_KEYS)
  end

  x.compare!
end

# Warming up --------------------------------------
# Micro::Service::Base     5.304k i/100ms
# Micro::Service::Strict
#                          4.516k i/100ms
#           Interactor     1.507k i/100ms
# Calculating -------------------------------------
# Micro::Service::Base     54.444k (± 2.8%) i/s -    275.808k in   5.070215s
# Micro::Service::Strict
#                          45.996k (± 1.8%) i/s -    230.316k in   5.008931s
#           Interactor     15.363k (± 2.2%) i/s -     76.857k in   5.005209s

# Comparison:
# Micro::Service::Base:    54444.5 i/s
# Micro::Service::Strict:  45995.8 i/s - 1.18x  slower
#             Interactor:  15363.0 i/s - 3.54x  slower
