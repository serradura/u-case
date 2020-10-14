require 'bundler/inline'

require 'forwardable'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'benchmark-ips', '~> 2.7', '>= 2.7.2'

  gem 'interactor', '~> 3.1', '>= 3.1.1'

  gem 'u-case', '~> 4.1.0'
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
# Interactor::Organizer             1.809k i/100ms
# Micro::Cases.flow([])             7.808k i/100ms
# Micro::Case flow in a class       4.816k i/100ms
# Micro::Case including the class   4.094k i/100ms
# Micro::Case::Result#|             7.656k i/100ms
# Micro::Case::Result#then          7.138k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer             24.290k (±24.0%) i/s -    113.967k in   5.032825s
# Micro::Cases.flow([])             74.790k (±11.1%) i/s -    374.784k in   5.071740s
# Micro::Case flow in a class       47.043k (± 8.0%) i/s -    235.984k in   5.047477s
# Micro::Case including the class   42.030k (± 8.5%) i/s -    208.794k in   5.002138s
# Micro::Case::Result#|             80.936k (±15.9%) i/s -    398.112k in   5.052531s
# Micro::Case::Result#then          71.459k (± 8.8%) i/s -    356.900k in   5.030526s

# Comparison:
# Micro::Case::Result#|:            80936.2 i/s
# Micro::Cases.flow([]):            74790.1 i/s - same-ish: difference falls within error
# Micro::Case::Result#then:         71459.5 i/s - same-ish: difference falls within error
# Micro::Case flow in a class:      47042.6 i/s - 1.72x  (± 0.00) slower
# Micro::Case including the class:  42030.2 i/s - 1.93x  (± 0.00) slower
# Interactor::Organizer:            24290.3 i/s - 3.33x  (± 0.00) slower
