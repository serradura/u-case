require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'u-case', '~> 2.6.0'
end

# Micro::Case::Result.disable_transition_tracking

class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success { { number: a * b } }
    else
      Failure(:invalid_data)
    end
  end
end

Multiply.call(a: 2, 'b' => 2)

report = MemoryProfiler.report do
  Multiply.call(a: 2, 'b' => 2)
end

report.pretty_print
