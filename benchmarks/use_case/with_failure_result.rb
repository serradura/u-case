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

  gem 'u-case', '~> 3.0.0.rc8'
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
#           Interactor     1.324k i/100ms
# Trailblazer::Operation   1.525k i/100ms
#          Dry::Monads     7.126k i/100ms
#     Dry::Transaction   499.000  i/100ms
#          Micro::Case     9.919k i/100ms
#  Micro::Case::Strict     7.837k i/100ms
#    Micro::Case::Safe     9.762k i/100ms

# Calculating -------------------------------------
#           Interactor     13.959k (± 2.5%) i/s -     70.172k in   5.030240s
# Trailblazer::Operation   15.035k (± 2.2%) i/s -     76.250k in   5.074108s
#          Dry::Monads     71.330k (± 2.4%) i/s -    363.426k in   5.097993s
#     Dry::Transaction      5.068k (± 1.9%) i/s -     25.449k in   5.023922s
#          Micro::Case     98.821k (± 2.9%) i/s -    495.950k in   5.023421s
#  Micro::Case::Strict     79.936k (± 3.1%) i/s -    399.687k in   5.005435s
#    Micro::Case::Safe     98.695k (± 1.9%) i/s -    497.862k in   5.046246s

# Comparison:
#          Micro::Case:    98820.8 i/s
#    Micro::Case::Safe:    98695.0 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    79935.9 i/s - 1.24x  (± 0.00) slower
#          Dry::Monads:    71329.7 i/s - 1.39x  (± 0.00) slower
# Trailblazer::Operation:  15034.9 i/s - 6.57x  (± 0.00) slower
#           Interactor:    13958.7 i/s - 7.08x  (± 0.00) slower
#     Dry::Transaction:     5067.5 i/s - 19.50x  (± 0.00) slower
