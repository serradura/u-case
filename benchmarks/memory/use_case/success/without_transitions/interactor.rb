require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'memory_profiler'

  gem 'interactor', '~> 3.1'
end

class Multiply
  include Interactor

  def call
    a = context.a
    b = context.b

    if a.is_a?(Numeric) && b.is_a?(Numeric)
      context.number = a * b
    else
      context.fail!(type: :invalid_data)
    end
  end
end

Multiply.call(a: 2, 'b' => 2)

report = MemoryProfiler.report do
  Multiply.call(a: 2, 'b' => 2)
end

report.pretty_print
