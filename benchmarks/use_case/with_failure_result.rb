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
#           Interactor     1.331k i/100ms
# Trailblazer::Operation
#                          1.544k i/100ms
#          Dry::Monads     6.343k i/100ms
#     Dry::Transaction   456.000  i/100ms
#          Micro::Case    10.429k i/100ms
#  Micro::Case::Strict     8.109k i/100ms
#    Micro::Case::Safe    10.280k i/100ms
# Calculating -------------------------------------
#           Interactor     13.487k (± 1.9%) i/s -     67.881k in   5.035059s
# Trailblazer::Operation
#                          15.658k (± 1.6%) i/s -     78.744k in   5.030427s
#          Dry::Monads     64.240k (± 1.8%) i/s -    323.493k in   5.037461s
#     Dry::Transaction      4.567k (± 1.3%) i/s -     23.256k in   5.092699s
#          Micro::Case    108.510k (± 2.3%) i/s -    542.308k in   5.000605s
#  Micro::Case::Strict     83.527k (± 1.4%) i/s -    421.668k in   5.049245s
#    Micro::Case::Safe    105.641k (± 3.7%) i/s -    534.560k in   5.067836s

# Comparison:
#          Micro::Case:   108510.0 i/s
#    Micro::Case::Safe:   105640.6 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    83526.8 i/s - 1.30x  slower
#          Dry::Monads:    64240.1 i/s - 1.69x  slower
# Trailblazer::Operation:  15657.7 i/s - 6.93x  slower
#           Interactor:    13486.7 i/s - 8.05x  slower
#     Dry::Transaction:     4567.3 i/s - 23.76x  slower
