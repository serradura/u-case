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

  gem 'u-case', '~> 2.6.0'
end

require 'benchmark/ips'

require_relative 'multiply'

Micro::Case::Result.disable_transition_tracking

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
#           Interactor     2.897k i/100ms
# Trailblazer::Operation   1.494k i/100ms
#          Dry::Monads    13.854k i/100ms
#     Dry::Transaction   561.000  i/100ms
#          Micro::Case    10.523k i/100ms
#  Micro::Case::Strict     7.982k i/100ms
#    Micro::Case::Safe    10.568k i/100ms

# Calculating -------------------------------------
#           Interactor     29.458k (± 3.4%) i/s -    147.747k in   5.021405s
# Trailblazer::Operation   14.715k (± 1.8%) i/s -     74.700k in   5.078128s
#          Dry::Monads    134.801k (± 8.7%) i/s -    678.846k in   5.088739s
#     Dry::Transaction      5.643k (± 2.1%) i/s -     28.611k in   5.072969s
#          Micro::Case    105.909k (± 2.4%) i/s -    536.673k in   5.070329s
#  Micro::Case::Strict     84.234k (± 1.5%) i/s -    423.046k in   5.023447s
#    Micro::Case::Safe    105.725k (± 1.9%) i/s -    538.968k in   5.099817s

# Comparison:
#          Dry::Monads:   134801.0 i/s
#          Micro::Case:   105909.2 i/s - 1.27x  (± 0.00) slower
#    Micro::Case::Safe:   105725.0 i/s - 1.28x  (± 0.00) slower
#  Micro::Case::Strict:    84234.4 i/s - 1.60x  (± 0.00) slower
#           Interactor:    29458.2 i/s - 4.58x  (± 0.00) slower
# Trailblazer::Operation:    14714.9 i/s - 9.16x  (± 0.00) slower
#     Dry::Transaction:     5642.6 i/s - 23.89x  (± 0.00) slower
