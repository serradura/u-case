require 'bundler/inline'

require 'forwardable'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'dry-monads', '~> 1.3', '>= 1.3.1'
  gem 'dry-transaction', '~> 0.13.0'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'trailblazer-operation', '~> 0.6.2', require: 'trailblazer/operation'

  gem 'u-case', '~> 3.0.0.rc4'
end

require 'benchmark/ips'

require_relative 'multiply'

Micro::Case.config do |config|
  # Use to enable/disable the `Micro::Case::Results#transitions` tracking.
  config.enable_transitions = false
end

SYMBOL_KEYS = { a: nil, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => '' }

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
#           Interactor     1.408k i/100ms
# Trailblazer::Operation   1.492k i/100ms
#          Dry::Monads     7.224k i/100ms
#     Dry::Transaction   501.000  i/100ms
#          Micro::Case     9.664k i/100ms
#  Micro::Case::Strict     7.823k i/100ms
#    Micro::Case::Safe     9.464k i/100ms

# Calculating -------------------------------------
#           Interactor     13.770k (± 4.3%) i/s -     68.992k in   5.020330s
# Trailblazer::Operation   14.786k (± 5.3%) i/s -     74.600k in   5.064700s
#          Dry::Monads     70.251k (± 6.7%) i/s -    353.976k in   5.063010s
#     Dry::Transaction      4.994k (± 4.0%) i/s -     25.050k in   5.023997s
#          Micro::Case     94.620k (± 3.8%) i/s -    473.536k in   5.012483s
#  Micro::Case::Strict     76.059k (± 3.0%) i/s -    383.327k in   5.044482s
#    Micro::Case::Safe     91.719k (± 5.6%) i/s -    463.736k in   5.072552s

# Comparison:
#          Micro::Case:    94619.6 i/s
#    Micro::Case::Safe:    91719.4 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    76058.7 i/s - 1.24x  (± 0.00) slower
#          Dry::Monads:    70250.6 i/s - 1.35x  (± 0.00) slower
# Trailblazer::Operation:  14786.1 i/s - 6.40x  (± 0.00) slower
#           Interactor:    13770.0 i/s - 6.87x  (± 0.00) slower
#     Dry::Transaction:    4994.4 i/s - 18.95x  (± 0.00) slower
