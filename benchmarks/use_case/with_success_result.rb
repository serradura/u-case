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

  gem 'u-case', '~> 3.0.0.rc9'
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
#           Interactor     2.915k i/100ms
# Trailblazer::Operation   1.543k i/100ms
#          Dry::Monads    14.288k i/100ms
#     Dry::Transaction   571.000  i/100ms
#          Micro::Case    10.418k i/100ms
#  Micro::Case::Strict     8.296k i/100ms
#    Micro::Case::Safe    10.254k i/100ms

# Calculating -------------------------------------
#           Interactor     29.101k (± 2.1%) i/s -    145.750k in   5.010660s
# Trailblazer::Operation   15.031k (± 2.0%) i/s -     75.607k in   5.032071s
#          Dry::Monads    141.730k (± 3.1%) i/s -    714.400k in   5.045546s
#     Dry::Transaction      5.674k (± 1.9%) i/s -     28.550k in   5.033564s
#          Micro::Case    103.541k (± 1.6%) i/s -    520.900k in   5.032077s
#  Micro::Case::Strict     83.045k (± 2.4%) i/s -    423.096k in   5.098031s
#    Micro::Case::Safe    101.662k (± 1.5%) i/s -    512.700k in   5.044386s

# Comparison:
#          Dry::Monads:   141730.1 i/s
#          Micro::Case:   103541.3 i/s - 1.37x  (± 0.00) slower
#    Micro::Case::Safe:   101662.2 i/s - 1.39x  (± 0.00) slower
#  Micro::Case::Strict:    83044.6 i/s - 1.71x  (± 0.00) slower
#           Interactor:    29100.8 i/s - 4.87x  (± 0.00) slower
# Trailblazer::Operation:  15031.4 i/s - 9.43x  (± 0.00) slower
#     Dry::Transaction:     5674.0 i/s - 24.98x  (± 0.00) slower
