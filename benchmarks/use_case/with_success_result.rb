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
#           Interactor     3.056k i/100ms
# Trailblazer::Operation   1.480k i/100ms
#          Dry::Monads    14.316k i/100ms
#     Dry::Transaction   576.000  i/100ms
#          Micro::Case    10.388k i/100ms
#  Micro::Case::Strict     8.223k i/100ms
#    Micro::Case::Safe    10.057k i/100ms

# Calculating -------------------------------------
#           Interactor     30.694k (± 2.3%) i/s -    155.856k in   5.080475s
# Trailblazer::Operation   14.581k (± 3.9%) i/s -     74.000k in   5.083091s
#          Dry::Monads    139.038k (± 3.0%) i/s -    701.484k in   5.049921s
#     Dry::Transaction      5.728k (± 3.6%) i/s -     28.800k in   5.034599s
#          Micro::Case    100.712k (± 3.4%) i/s -    509.012k in   5.060139s
#  Micro::Case::Strict     81.513k (± 3.4%) i/s -    411.150k in   5.049962s
#    Micro::Case::Safe    101.497k (± 3.1%) i/s -    512.907k in   5.058463s

# Comparison:
#          Dry::Monads:   139037.7 i/s
#    Micro::Case::Safe:   101497.3 i/s - 1.37x  (± 0.00) slower
#          Micro::Case:   100711.6 i/s - 1.38x  (± 0.00) slower
#  Micro::Case::Strict:    81512.9 i/s - 1.71x  (± 0.00) slower
#           Interactor:    30694.2 i/s - 4.53x  (± 0.00) slower
# Trailblazer::Operation:  14580.8 i/s - 9.54x  (± 0.00) slower
#     Dry::Transaction:    5728.0 i/s - 24.27x  (± 0.00) slower
