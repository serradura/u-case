require 'bundler/inline'

require 'forwardable'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'dry-monads', '~> 1.3', '>= 1.3.1'
  gem 'dry-transaction', '~> 0.13.0'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'trailblazer-activity', '~> 0.10.1'
  gem 'trailblazer-operation', '~> 0.6.2', require: 'trailblazer/operation'

  gem 'u-case', '~> 3.1.0'
end

require_relative '../../examples/use_case/multiply_with/all'
require_relative 'call_use_cases'

Micro::Case.config do |config|
  config.enable_transitions = false
end

require 'benchmark/ips'

Benchmark.ips(&CallUseCases.(
  params: { a: 2, 'b' => 2 }
))

# Warming up --------------------------------------
#           Interactor     5.151k i/100ms
# Trailblazer::Operation   3.805k i/100ms
#          Dry::Monads    28.153k i/100ms
#     Dry::Transaction     1.063k i/100ms
#          Micro::Case    15.159k i/100ms
#    Micro::Case::Safe    15.172k i/100ms
#  Micro::Case::Strict    12.557k i/100ms

# Calculating -------------------------------------
#           Interactor     53.016k (± 1.8%) i/s -    267.852k in   5.053967s
# Trailblazer::Operation   38.314k (± 1.7%) i/s -    194.055k in   5.066374s
#          Dry::Monads    281.515k (± 2.4%) i/s -      1.408M in   5.003266s
#     Dry::Transaction     10.441k (± 2.1%) i/s -     53.150k in   5.092957s
#          Micro::Case    151.711k (± 1.7%) i/s -    773.109k in   5.097555s
#    Micro::Case::Safe    145.801k (± 6.7%) i/s -    728.256k in   5.022666s
#  Micro::Case::Strict    115.636k (± 8.4%) i/s -    577.622k in   5.042079s

# Comparison:
#          Dry::Monads:   281515.4 i/s
#          Micro::Case:   151711.3 i/s - 1.86x  (± 0.00) slower
#    Micro::Case::Safe:   145800.8 i/s - 1.93x  (± 0.00) slower
#  Micro::Case::Strict:   115635.8 i/s - 2.43x  (± 0.00) slower
#           Interactor:    53016.2 i/s - 5.31x  (± 0.00) slower
# Trailblazer::Operation:  38314.2 i/s - 7.35x  (± 0.00) slower
#     Dry::Transaction:    10440.7 i/s - 26.96x  (± 0.00) slower
