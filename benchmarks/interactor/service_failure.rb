require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.13.0'
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
#           Interactor     1.529k i/100ms
# Micro::Service::Base    12.440k i/100ms
# Micro::Service::Strict
#                          9.534k i/100ms
# Calculating -------------------------------------
#           Interactor     15.736k (± 3.0%) i/s -     79.508k in   5.057323s
# Micro::Service::Base    129.999k (± 1.5%) i/s -    659.320k in   5.072863s
# Micro::Service::Strict
#                          98.943k (± 1.5%) i/s -    495.768k in   5.011742s

# Comparison:
# Micro::Service::Base:    129998.6 i/s
# Micro::Service::Strict:  98942.8 i/s - 1.31x  slower
#           Interactor:    15736.4 i/s - 8.26x  slower
