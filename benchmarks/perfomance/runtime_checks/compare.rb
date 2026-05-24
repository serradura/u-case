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

# Sample runs on Apple Silicon (M-series), 3×(2s warmup + 5s measure).
# Δ column = (disabled - enabled) / enabled. * = delta exceeds combined ±stddev.
#
#                              single_use_case   use_case→use_case   flow_3_steps
# Ruby 2.7.8     (no JIT)        +2.80%             +1.37%             +2.80% *
# Ruby 3.2.11    (no YJIT)       -0.15%             +1.02%             +2.19%
# Ruby 3.2.11    +YJIT           +3.22% *           +3.64%             +5.15% *
# Ruby 4.0.1     +PRISM          +7.41% *           +5.99% *           +4.32% *
#
# Reading:
#   - Without a JIT (Ruby 2.7, Ruby 3.2-default — the typical Rails setup),
#     the toggle's effect is within noise. There is no perf reason for a
#     stock-Rails app to flip it on.
#   - With YJIT (Ruby 3.2 --yjit, which Rails 7.2+ exposes as
#     `config.yjit = true` but ships disabled), the toggle is worth
#     3–5% on hot paths.
#   - With PRISM (Ruby 4.0+, the default parser/bytecode), the gap widens
#     further (4–7%): PRISM appears to inline the no-op methods to
#     near-zero cost while the `is_a?` chain on the enabled side stays as
#     real work.
#
# JIT throughput effect (independent of this toggle): enabling YJIT on
# Ruby 3.2 roughly +54% on `single_use_case` (187k → 287k i/s).
#
# Methodology note: the first iteration of this benchmark toggled
# `Micro::Case.check` mid-process and every comparison came back
# "same-ish". That was an artifact — swapping the reference invalidates
# Ruby's inline caches, so the second mode measured ran with caches
# re-warming during the measurement window. Hence the per-mode subprocess
# split: each mode boots fresh with its own caches.
