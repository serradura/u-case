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
#           Interactor     3.017k i/100ms
#          Micro::Case    12.671k i/100ms
#  Micro::Case::Strict     9.881k i/100ms
#    Micro::Case::Safe    12.501k i/100ms
#          Dry::Monads    14.360k i/100ms
#      Dry::Monads.new    13.772k i/100ms
#     Dry::Transaction     5.277k i/100ms
# Dry::Transaction.new   581.000  i/100ms
# Calculating -------------------------------------
#           Interactor     30.490k (± 2.2%) i/s -    153.867k in   5.049013s
#          Micro::Case    133.609k (± 1.9%) i/s -    671.563k in   5.028303s
#  Micro::Case::Strict    101.804k (± 1.7%) i/s -    513.812k in   5.048625s
#    Micro::Case::Safe    132.174k (± 1.0%) i/s -    662.553k in   5.013220s
#          Dry::Monads    150.389k (± 1.1%) i/s -    761.080k in   5.061395s
#      Dry::Monads.new    143.296k (± 1.1%) i/s -    729.916k in   5.094455s
#     Dry::Transaction     53.897k (± 1.4%) i/s -    274.404k in   5.092316s
# Dry::Transaction.new      5.900k (± 1.0%) i/s -     29.631k in   5.022947s

# Comparison:
#          Dry::Monads:   150389.4 i/s
#      Dry::Monads.new:   143295.9 i/s - 1.05x  slower
#          Micro::Case:   133608.8 i/s - 1.13x  slower
#    Micro::Case::Safe:   132173.6 i/s - 1.14x  slower
#  Micro::Case::Strict:   101803.5 i/s - 1.48x  slower
#     Dry::Transaction:    53896.8 i/s - 2.79x  slower
#           Interactor:    30490.3 i/s - 4.93x  slower
# Dry::Transaction.new:     5899.8 i/s - 25.49x  slower
