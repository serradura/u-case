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
#           Interactor     1.339k i/100ms
# Trailblazer::Operation   1.393k i/100ms
#          Dry::Monads     7.208k i/100ms
#     Dry::Transaction     423.000  i/100ms
#          Micro::Case     9.620k i/100ms
#  Micro::Case::Strict     8.238k i/100ms
#    Micro::Case::Safe     9.906k i/100ms

# Calculating -------------------------------------
#           Interactor     13.227k (± 3.3%) i/s -     66.950k in   5.067145s
# Trailblazer::Operation   14.591k (± 4.0%) i/s -     73.829k in   5.069162s
#          Dry::Monads     71.779k (± 2.5%) i/s -    360.400k in   5.024294s
#     Dry::Transaction      4.978k (± 3.3%) i/s -     24.957k in   5.019153s
#          Micro::Case    103.957k (± 1.8%) i/s -    529.100k in   5.091221s
#  Micro::Case::Strict     83.094k (± 2.0%) i/s -    420.138k in   5.058233s
#    Micro::Case::Safe    104.339k (± 1.7%) i/s -    525.018k in   5.033381s

# Comparison:
#    Micro::Case::Safe:   104339.4 i/s
#          Micro::Case:   103957.2 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    83094.5 i/s - 1.26x  (± 0.00) slower
#          Dry::Monads:    71779.2 i/s - 1.45x  (± 0.00) slower
# Trailblazer::Operation:    14590.6 i/s - 7.15x  (± 0.00) slower
#           Interactor:    13226.5 i/s - 7.89x  (± 0.00) slower
#     Dry::Transaction:     4978.1 i/s - 20.96x  (± 0.00) slower
