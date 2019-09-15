require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-case', '~> 1.0.0.rc1'
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

class MSB_Multiply < Micro::Case::Base
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure(:invalid_data)
    end
  end
end

class MSS_Multiply < Micro::Case::Strict
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

  x.report('Micro::Case::Base') do
    MSB_Multiply.call(SYMBOL_KEYS)
    MSB_Multiply.call(STRING_KEYS)
  end

  x.report('Micro::Case::Strict') do
    MSS_Multiply.call(SYMBOL_KEYS)
    MSS_Multiply.call(STRING_KEYS)
  end

  x.compare!
end

# Warming up --------------------------------------
#           Interactor     1.521k i/100ms
# Micro::Case::Base    11.209k i/100ms
# Micro::Case::Strict
#                          8.794k i/100ms
# Calculating -------------------------------------
#           Interactor     14.564k (± 7.8%) i/s -     73.008k in   5.048979s
# Micro::Case::Base    116.319k (± 1.7%) i/s -    582.868k in   5.012372s
# Micro::Case::Strict
#                          89.790k (± 3.4%) i/s -    448.494k in   5.001098s

# Comparison:
# Micro::Case::Base:   116318.8 i/s
# Micro::Case::Strict:  89790.0 i/s - 1.30x  slower
#           Interactor: 14564.3 i/s - 7.99x  slower
