# frozen_string_literal: true
#
# Runs checks_enabled.rb and checks_disabled.rb in two separate Ruby
# subprocesses (each booted fresh, so neither one's method/inline caches
# pollute the other's measurement) and prints a side-by-side comparison
# from the JSON each subprocess emits.
#
# Usage:
#   unset BUNDLE_GEMFILE && ruby benchmarks/perfomance/runtime_checks/compare.rb
#
# To run on a specific Ruby (via mise / asdf / rbenv), set RUBY:
#   unset BUNDLE_GEMFILE && RUBY="mise exec ruby@2.7.8 -- ruby" \
#     ruby benchmarks/perfomance/runtime_checks/compare.rb

require 'json'
require 'tmpdir'

ruby_cmd = ENV.fetch('RUBY', 'ruby').split

modes = {
  enabled:  File.expand_path('checks_enabled.rb',  __dir__),
  disabled: File.expand_path('checks_disabled.rb', __dir__),
}

results = modes.map do |mode, file|
  json_path = File.join(Dir.tmpdir, "u_case_bench_#{mode}_#{$$}.json")

  puts "\n=== Running #{mode} (#{file}) ==="
  argv = [*ruby_cmd, file, json_path]

  unless system(*argv)
    abort "#{mode} run failed (exit status #{$?.exitstatus})"
  end

  data = JSON.parse(File.read(json_path))
  File.unlink(json_path)

  [mode, data.each_with_object({}) { |r, h| h[r['name']] = r }]
end.to_h

scenarios = results[:enabled].keys

puts
puts '=' * 92
puts 'Comparison (each mode measured in its own Ruby process, JIT/cache state fresh)'
puts '=' * 92
printf "%-28s  %18s  %18s  %12s\n", 'scenario', 'enabled (default)', 'disabled', 'delta (D-E)/E'
puts '-' * 92

scenarios.each do |name|
  e = results[:enabled][name]
  d = results[:disabled][name]

  e_ips, e_err = e.fetch('central_tendency'), e.fetch('stddev')
  d_ips, d_err = d.fetch('central_tendency'), d.fetch('stddev')

  e_pct = (e_err.to_f / e_ips) * 100
  d_pct = (d_err.to_f / d_ips) * 100
  delta = ((d_ips - e_ips) / e_ips) * 100

  # Flag whether the gap is within combined noise (very rough: sum of
  # the two stddevs). Not a real statistical test, just a guard against
  # over-reading small numbers.
  combined_noise_pct = e_pct + d_pct
  marker = delta.abs > combined_noise_pct ? '*' : ' '

  printf "%-28s  %10.0f i/s ±%4.1f%%  %10.0f i/s ±%4.1f%%  %+8.2f%% %s\n",
    name, e_ips, e_pct, d_ips, d_pct, delta, marker
end

puts '-' * 92
puts '* delta exceeds combined ±stddev — likely a real effect, not noise.'
puts '  (no marker = within combined noise; treat as no measurable difference.)'

# Sample runs on Apple Silicon (M-series), 3×(2s warmup + 5s measure):
#
# Ruby 4.0.1 +PRISM
#   single_use_case                   178k ±4.9%   192k ±1.9%   +7.41% *
#   use_case_calling_another         90.6k ±3.1%  96.1k ±1.6%   +5.99% *
#   flow_3_steps                     59.8k ±1.5%  62.4k ±2.8%   +4.32% *
#
# Ruby 2.7.8 (no JIT)
#   single_use_case                   185k ±2.7%   190k ±1.6%   +2.80%
#   use_case_calling_another         98.6k ±1.2%  99.9k ±7.0%   +1.37%
#   flow_3_steps                     64.3k ±1.0%  66.1k ±1.3%   +2.80% *
#
# Reading: each scenario is faster with checks disabled. The win is larger
# on modern Ruby (PRISM inlines the no-op methods to near-zero cost while
# the `is_a?` chain on the enabled side stays as real work) and smaller on
# Ruby 2.7 where there's no JIT to widen the gap.
#
# The in-process toggle approach hid this entirely (every comparison
# returned "same-ish") because swapping `Micro::Case.check` mid-process
# invalidated inline caches and the second mode measured ran with caches
# re-warming during the measurement window. Hence the per-mode subprocess
# split: each mode boots fresh with its own caches.
