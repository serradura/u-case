require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'u-case', '~> 2.0.0'
end

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

SYMBOL_KEYS = { a: nil, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => '' }

report = MemoryProfiler.report do
  Multiply.call(SYMBOL_KEYS)
  Multiply.call(STRING_KEYS)
end

report.pretty_print
