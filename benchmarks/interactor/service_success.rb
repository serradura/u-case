require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-service', '~> 0.14.0'
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
      context.fail!(:invalid_data)
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

SYMBOL_KEYS = { a: 2, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => 1 }

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
#           Interactor     2.947k i/100ms
# Micro::Service::Base    11.900k i/100ms
# Micro::Service::Strict
#                          9.213k i/100ms
# Calculating -------------------------------------
#           Interactor     28.336k (± 7.1%) i/s -    141.456k in   5.018427s
# Micro::Service::Base    124.627k (± 2.7%) i/s -    630.700k in   5.064614s
# Micro::Service::Strict
#                          95.577k (± 2.0%) i/s -    479.076k in   5.014468s

# Comparison:
# Micro::Service::Base:   124627.3 i/s
# Micro::Service::Strict:  95577.3 i/s - 1.30x  slower
#           Interactor:    28335.8 i/s - 4.40x  slower
