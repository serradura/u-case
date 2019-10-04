require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'
  gem 'interactor', '~> 3.1', '>= 3.1.1'
  gem 'u-case', '~> 1.0.0'
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
#           Interactor     2.943k i/100ms
# Micro::Case::Base    12.267k i/100ms
# Micro::Case::Strict
#                          9.368k i/100ms
# Calculating -------------------------------------
#           Interactor     29.998k (± 2.5%) i/s -    150.093k in   5.006612s
# Micro::Case::Base    125.269k (± 3.4%) i/s -    625.617k in   5.000142s
# Micro::Case::Strict
#                          96.087k (± 2.5%) i/s -    487.136k in   5.073155s

# Comparison:
# Micro::Case::Base:   125269.5 i/s
# Micro::Case::Strict:  96087.3 i/s - 1.30x  slower
#           Interactor: 29997.7 i/s - 4.18x  slower
