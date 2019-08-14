require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.12.0'
end

require 'benchmark/ips'

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

SYMBOL_KEYS = { a: nil, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => '' }

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Interactor') do
    IT_Multiply.call(SYMBOL_KEYS)
    IT_Multiply.call(STRING_KEYS)
  end

  x.report('Micro::Service::Base') do
    MSB_Multiply.call(SYMBOL_KEYS)
    MSB_Multiply.call(STRING_KEYS)
  end

  x.report('Micro::Service::Strict') do
    MSS_Multiply.call(SYMBOL_KEYS)
    MSS_Multiply.call(STRING_KEYS)
  end

  x.compare!
end

# Warming up --------------------------------------
#           Interactor     1.507k i/100ms
# Micro::Service::Base    12.902k i/100ms
# Micro::Service::Strict
#                          9.758k i/100ms
# Calculating -------------------------------------
#           Interactor     15.482k (± 2.6%) i/s -     78.364k in   5.065166s
# Micro::Service::Base    134.861k (± 1.3%) i/s -    683.806k in   5.071263s
# Micro::Service::Strict
#                         101.331k (± 1.5%) i/s -    507.416k in   5.008688s

# Comparison:
# Micro::Service::Base:   134861.1 i/s
# Micro::Service::Strict: 101331.5 i/s - 1.33x  slower
#           Interactor:   15482.0 i/s - 8.71x  slower
