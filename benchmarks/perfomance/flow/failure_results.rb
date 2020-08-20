require 'bundler/inline'

require 'forwardable'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 3.1.0'
end

require_relative '../../examples/flow/add_five_with/all'
require_relative 'call_flows'

Micro::Case.config do |config|
  config.enable_transitions = false
end

require 'benchmark/ips'

Benchmark.ips(&CallFlows.(
  params: { text: 'b' }
))

# Warming up --------------------------------------
# Interactor::Organizer            2.167k i/100ms
# Micro::Cases.flow([])           11.797k i/100ms
# Micro::Case flow in a class      7.783k i/100ms
# Micro::Case including the class  7.097k i/100ms
# Micro::Case::Result#|           14.398k i/100ms
# Micro::Case::Result#then        12.719k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            21.863k (± 2.5%) i/s -    110.517k in   5.058420s
# Micro::Cases.flow([])           118.124k (± 1.8%) i/s -    601.647k in   5.095102s
# Micro::Case flow in a class      77.801k (± 1.5%) i/s -    389.150k in   5.003002s
# Micro::Case including the class  73.533k (± 2.1%) i/s -    369.044k in   5.021076s
# Micro::Case::Result#|           153.746k (± 1.5%) i/s -    777.492k in   5.058177s
# Micro::Case::Result#then        126.897k (± 1.7%) i/s -    635.950k in   5.013059s

# Comparison:
# Micro::Case::Result#|:          153745.6 i/s
# Micro::Case::Result#then:       126896.6 i/s - 1.21x  (± 0.00) slower
# Micro::Cases.flow([]):          118123.9 i/s - 1.30x  (± 0.00) slower
# Micro::Case flow in a class:     77800.7 i/s - 1.98x  (± 0.00) slower
# Micro::Case including the class: 73532.9 i/s - 2.09x  (± 0.00) slower
# Interactor::Organizer:           21862.9 i/s - 7.03x  (± 0.00) slower
