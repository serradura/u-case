require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'dry-monads', '~> 1.3', '>= 1.3.1'
  gem 'dry-transaction', '~> 0.13.0'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 2.0.0'
end

require 'benchmark/ips'

require_relative 'multiply'

module Multiply
  WithDryMonadsSingleton = WithDryMonads.new
  WithDryTransactionSingleton = WithDryTransaction.new
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

  x.report('Dry::Monads') do
    Multiply::WithDryMonadsSingleton.call(SYMBOL_KEYS)
    Multiply::WithDryMonadsSingleton.call(STRING_KEYS)
  end

  x.report('Dry::Monads.new') do
    Multiply::WithDryMonads.new.call(SYMBOL_KEYS)
    Multiply::WithDryMonads.new.call(STRING_KEYS)
  end

  x.report('Dry::Transaction') do
    Multiply::WithDryTransactionSingleton.call(SYMBOL_KEYS)
    Multiply::WithDryTransactionSingleton.call(STRING_KEYS)
  end

  x.report('Dry::Transaction.new') do
    Multiply::WithDryTransaction.new.call(SYMBOL_KEYS)
    Multiply::WithDryTransaction.new.call(STRING_KEYS)
  end

  x.compare!
end

# Warming up --------------------------------------
#           Interactor     1.530k i/100ms
#          Micro::Case    11.423k i/100ms
#  Micro::Case::Strict     8.969k i/100ms
#    Micro::Case::Safe    11.166k i/100ms
#          Dry::Monads     6.909k i/100ms
#      Dry::Monads.new     6.775k i/100ms
#     Dry::Transaction     2.991k i/100ms
# Dry::Transaction.new   515.000  i/100ms
# Calculating -------------------------------------
#           Interactor     15.567k (± 1.7%) i/s -     78.030k in   5.013901s
#          Micro::Case    118.662k (± 1.8%) i/s -    593.996k in   5.007457s
#  Micro::Case::Strict     93.161k (± 1.3%) i/s -    466.388k in   5.007143s
#    Micro::Case::Safe    115.906k (± 1.6%) i/s -    580.632k in   5.010863s
#          Dry::Monads     71.294k (± 1.4%) i/s -    359.268k in   5.040143s
#      Dry::Monads.new     69.793k (± 1.7%) i/s -    352.300k in   5.049263s
#     Dry::Transaction     30.256k (± 1.1%) i/s -    152.541k in   5.042370s
# Dry::Transaction.new      5.156k (± 1.8%) i/s -     26.265k in   5.095326s

# Comparison:
#          Micro::Case:   118661.7 i/s
#    Micro::Case::Safe:   115906.0 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    93160.8 i/s - 1.27x  slower
#          Dry::Monads:    71294.4 i/s - 1.66x  slower
#      Dry::Monads.new:    69793.0 i/s - 1.70x  slower
#     Dry::Transaction:    30255.8 i/s - 3.92x  slower
#           Interactor:    15567.0 i/s - 7.62x  slower
# Dry::Transaction.new:     5156.5 i/s - 23.01x  slower
