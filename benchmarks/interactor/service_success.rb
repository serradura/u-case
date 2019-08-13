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
      context.fail!(:invalid_data)
    end
  end
end

SYMBOL_KEYS = { a: 2, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => 1 }

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
# Micro::Service::Base     5.365k i/100ms
# Micro::Service::Strict
#                          4.535k i/100ms
#           Interactor     2.620k i/100ms
# Calculating -------------------------------------
# Micro::Service::Base     51.795k (± 4.7%) i/s -    262.885k in   5.086671s
# Micro::Service::Strict
#                          46.253k (± 1.6%) i/s -    231.285k in   5.001748s
#           Interactor     29.561k (± 3.3%) i/s -    149.340k in   5.057720s

# Comparison:
# Micro::Service::Base:    51794.5 i/s
# Micro::Service::Strict:  46253.0 i/s - 1.12x  slower
#             Interactor:  29561.5 i/s - 1.75x  slower
