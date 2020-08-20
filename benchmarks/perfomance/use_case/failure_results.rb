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
  params: { a: nil, 'b' => 2 }
))

# Warming up --------------------------------------
#           Interactor     2.351k i/100ms
# Trailblazer::Operation   3.941k i/100ms
#          Dry::Monads    13.567k i/100ms
#     Dry::Transaction   927.000  i/100ms
#          Micro::Case    14.959k i/100ms
#    Micro::Case::Safe    14.904k i/100ms
#  Micro::Case::Strict    12.007k i/100ms

# Calculating -------------------------------------
#           Interactor     23.856k (± 1.7%) i/s -    119.901k in   5.027585s
# Trailblazer::Operation   39.830k (± 1.2%) i/s -    200.991k in   5.047032s
#          Dry::Monads    133.866k (± 2.5%) i/s -    678.350k in   5.070899s
#     Dry::Transaction      7.975k (± 8.6%) i/s -     39.861k in   5.036260s
#          Micro::Case    130.534k (±24.4%) i/s -    583.401k in   5.040907s
#    Micro::Case::Safe    140.794k (± 8.1%) i/s -    700.488k in   5.020935s
#  Micro::Case::Strict    102.641k (±21.3%) i/s -    480.280k in   5.020354s

# Comparison:
#    Micro::Case::Safe:   140794.0 i/s
#          Dry::Monads:   133865.5 i/s - same-ish: difference falls within error
#          Micro::Case:   130534.0 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:   102640.7 i/s - 1.37x  (± 0.00) slower
# Trailblazer::Operation:  39829.9 i/s - 3.53x  (± 0.00) slower
#           Interactor:    23856.0 i/s - 5.90x  (± 0.00) slower
#     Dry::Transaction:     7975.0 i/s - 17.65x  (± 0.00) slower
