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

  gem 'u-case', '~> 4.1.0'
end

require_relative '../../examples/use_case/multiply_with/all'
require_relative 'call_use_cases'

Micro::Case.config do |config|
  config.enable_transitions = false
end

require 'benchmark/ips'

Benchmark.ips(&CallUseCases.(
  params: { a: nil, 'b' => 2 }
))

# Warming up --------------------------------------
#           Interactor     2.626k i/100ms
# Trailblazer::Operation   2.343k i/100ms
#          Dry::Monads    13.386k i/100ms
#     Dry::Transaction   868.000  i/100ms
#          Micro::Case     7.603k i/100ms
#    Micro::Case::Safe     7.598k i/100ms
#  Micro::Case::Strict     6.178k i/100ms

# Calculating -------------------------------------
#           Interactor     27.037k (±24.9%) i/s -    128.674k in   5.102133s
# Trailblazer::Operation   29.016k (±12.4%) i/s -    145.266k in   5.074991s
#          Dry::Monads    135.387k (±15.1%) i/s -    669.300k in   5.055356s
#     Dry::Transaction      8.989k (± 9.2%) i/s -     45.136k in   5.084820s
#          Micro::Case     73.247k (± 9.9%) i/s -    364.944k in   5.030449s
#    Micro::Case::Safe     73.489k (± 9.6%) i/s -    364.704k in   5.007282s
#  Micro::Case::Strict     61.980k (± 8.0%) i/s -    308.900k in   5.014821s

# Comparison:
#          Dry::Monads:   135386.9 i/s
#    Micro::Case::Safe:    73489.3 i/s - 1.84x  (± 0.00) slower
#          Micro::Case:    73246.6 i/s - 1.85x  (± 0.00) slower
#  Micro::Case::Strict:    61979.7 i/s - 2.18x  (± 0.00) slower
# Trailblazer::Operation:    29016.4 i/s - 4.67x  (± 0.00) slower
#           Interactor:    27037.0 i/s - 5.01x  (± 0.00) slower
#     Dry::Transaction:     8988.6 i/s - 15.06x  (± 0.00) slower
