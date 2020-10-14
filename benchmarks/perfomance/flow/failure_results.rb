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
  params: { text: 'b' }
))

# Warming up --------------------------------------
# Interactor::Organizer            1.734k i/100ms
# Micro::Cases.flow([])            7.515k i/100ms
# Micro::Case flow in a class      4.636k i/100ms
# Micro::Case including the class  4.114k i/100ms
# Micro::Case::Result#|            7.588k i/100ms
# Micro::Case::Result#then         6.681k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            24.280k (±24.5%) i/s -    112.710k in   5.013334s
# Micro::Cases.flow([])            74.999k (± 9.8%) i/s -    375.750k in   5.055777s
# Micro::Case flow in a class      46.681k (± 9.3%) i/s -    236.436k in   5.105105s
# Micro::Case including the class  41.921k (± 8.9%) i/s -    209.814k in   5.043622s
# Micro::Case::Result#|            78.280k (±12.6%) i/s -    386.988k in   5.022146s
# Micro::Case::Result#then         68.898k (± 8.8%) i/s -    347.412k in   5.080116s

# Comparison:
# Micro::Case::Result#|:            78280.4 i/s
# Micro::Cases.flow([]):            74999.4 i/s - same-ish: difference falls within error
# Micro::Case::Result#then:         68898.4 i/s - same-ish: difference falls within error
# Micro::Case flow in a class:      46681.0 i/s - 1.68x  (± 0.00) slower
# Micro::Case including the class:  41920.8 i/s - 1.87x  (± 0.00) slower
# Interactor::Organizer:            24280.0 i/s - 3.22x  (± 0.00) slower
