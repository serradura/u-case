require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'dry-monads', '~> 1.3', '>= 1.3.1'
  gem 'dry-transaction', '~> 0.13.0'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'trailblazer-operation', '~> 0.6.0'

  gem 'u-case', '~> 2.0.0'
end

require 'benchmark/ips'

require_relative 'multiply'

SYMBOL_KEYS = { a: 2, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => 1 }

Benchmark.ips do |x|
  x.config(:time => 5, :warmup => 2)

  x.time = 5
  x.warmup = 2

  x.report('Interactor') do
    Multiply::WithInteractor.call(SYMBOL_KEYS)
    Multiply::WithInteractor.call(STRING_KEYS)
  end

  x.report('Trailblazer::Operation') do
    Multiply::WithTrailblazerOperation.call(params: SYMBOL_KEYS)
    Multiply::WithTrailblazerOperation.call(params: STRING_KEYS)
  end

  x.report('Dry::Monads') do
    Multiply::WithDryMonads.new.call(SYMBOL_KEYS)
    Multiply::WithDryMonads.new.call(STRING_KEYS)
  end

  x.report('Dry::Transaction') do
    Multiply::WithDryTransaction.new.call(SYMBOL_KEYS)
    Multiply::WithDryTransaction.new.call(STRING_KEYS)
  end

  x.report('Micro::Case') do
    Multiply::WithMicroCase.call(SYMBOL_KEYS)
    Multiply::WithMicroCase.call(STRING_KEYS)
  end

  x.report('Micro::Case::Strict') do
    Multiply::WithMicroCaseStrict.call(SYMBOL_KEYS)
    Multiply::WithMicroCaseStrict.call(STRING_KEYS)
  end

  x.report('Micro::Case::Safe') do
    Multiply::WithMicroCaseSafe.call(SYMBOL_KEYS)
    Multiply::WithMicroCaseSafe.call(STRING_KEYS)
  end

  x.compare!
end

# Warming up --------------------------------------
#           Interactor     2.865k i/100ms
# Trailblazer::Operation
#                          1.686k i/100ms
#          Dry::Monads    13.389k i/100ms
#     Dry::Transaction   551.000  i/100ms
#          Micro::Case    11.984k i/100ms
#  Micro::Case::Strict     9.102k i/100ms
#    Micro::Case::Safe    11.747k i/100ms
# Calculating -------------------------------------
#           Interactor     28.974k (± 2.7%) i/s -    146.115k in   5.046703s
# Trailblazer::Operation
#                          17.276k (± 1.8%) i/s -     87.672k in   5.076609s
#          Dry::Monads    139.353k (± 2.5%) i/s -    709.617k in   5.095599s
#     Dry::Transaction      5.572k (± 3.6%) i/s -     28.101k in   5.050376s
#          Micro::Case    124.749k (± 1.9%) i/s -    635.152k in   5.093310s
#  Micro::Case::Strict     93.417k (± 4.8%) i/s -    473.304k in   5.081341s
#    Micro::Case::Safe    120.607k (± 3.2%) i/s -    610.844k in   5.070394s

# Comparison:
#          Dry::Monads:   139352.5 i/s
#          Micro::Case:   124749.4 i/s - 1.12x  slower
#    Micro::Case::Safe:   120607.3 i/s - 1.16x  slower
#  Micro::Case::Strict:    93417.3 i/s - 1.49x  slower
#           Interactor:    28974.4 i/s - 4.81x  slower
# Trailblazer::Operation:  17275.6 i/s - 8.07x  slower
#     Dry::Transaction:     5571.7 i/s - 25.01x  slower
