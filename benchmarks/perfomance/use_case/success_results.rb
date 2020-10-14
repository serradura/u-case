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
  params: { a: 2, 'b' => 2 }
))

# Warming up --------------------------------------
#           Interactor     5.711k i/100ms
# Trailblazer::Operation
#                          2.283k i/100ms
#          Dry::Monads    31.130k i/100ms
#     Dry::Transaction   994.000  i/100ms
#          Micro::Case     7.911k i/100ms
#    Micro::Case::Safe     7.911k i/100ms
#  Micro::Case::Strict     6.248k i/100ms

# Calculating -------------------------------------
#           Interactor     59.746k (±29.9%) i/s -    274.128k in   5.049901s
# Trailblazer::Operation
#                          28.424k (±15.8%) i/s -    141.546k in   5.087882s
#          Dry::Monads    315.635k (± 6.1%) i/s -      1.588M in   5.048914s
#     Dry::Transaction     10.131k (± 6.4%) i/s -     50.694k in   5.025150s
#          Micro::Case     75.838k (± 9.7%) i/s -    379.728k in   5.052573s
#    Micro::Case::Safe     75.461k (±10.1%) i/s -    379.728k in   5.079238s
#  Micro::Case::Strict     64.235k (± 9.0%) i/s -    324.896k in   5.097028s

# Comparison:
#          Dry::Monads:   315635.1 i/s
#          Micro::Case:    75837.7 i/s - 4.16x  (± 0.00) slower
#    Micro::Case::Safe:    75461.3 i/s - 4.18x  (± 0.00) slower
#  Micro::Case::Strict:    64234.9 i/s - 4.91x  (± 0.00) slower
#           Interactor:    59745.5 i/s - 5.28x  (± 0.00) slower
# Trailblazer::Operation:    28423.9 i/s - 11.10x  (± 0.00) slower
#     Dry::Transaction:    10130.9 i/s - 31.16x  (± 0.00) slower
