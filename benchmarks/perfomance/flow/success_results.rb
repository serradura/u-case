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
  params: { text: 0 }
))

# Warming up --------------------------------------
# Interactor::Organizer            2.163k i/100ms
# Micro::Cases.flow([])           13.158k i/100ms
# Micro::Case flow in a class      8.400k i/100ms
# Micro::Case including the class  8.008k i/100ms
# Micro::Case::Result#|           17.151k i/100ms
# Micro::Case::Result#then        14.121k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            22.467k (± 1.8%) i/s -    112.476k in   5.007787s
# Micro::Cases.flow([])           133.183k (± 1.5%) i/s -    671.058k in   5.039815s
# Micro::Case flow in a class      84.083k (± 1.8%) i/s -    428.400k in   5.096623s
# Micro::Case including the class  80.574k (± 1.6%) i/s -    408.408k in   5.070029s
# Micro::Case::Result#|           172.734k (± 1.1%) i/s -    874.701k in   5.064429s
# Micro::Case::Result#then        139.799k (± 1.7%) i/s -    706.050k in   5.052035s

# Comparison:
# Micro::Case::Result#|:          172734.4 i/s
# Micro::Case::Result#then:       139799.0 i/s - 1.24x  (± 0.00) slower
# Micro::Cases.flow([]):          133182.9 i/s - 1.30x  (± 0.00) slower
# Micro::Case flow in a class:     84082.6 i/s - 2.05x  (± 0.00) slower
# Micro::Case including the class: 80574.3 i/s - 2.14x  (± 0.00) slower
# Interactor::Organizer:           22467.4 i/s - 7.69x  (± 0.00) slower
