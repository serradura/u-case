require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  ruby '>= 2.4.0'

  gem 'ruby-prof'

  gem 'u-case', '~> 3.1.0'
end

class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(result: { number: a * b })
    else
      Failure(:invalid_data)
    end
  end
end

# RubyProf.measure_mode = RubyProf::WALL_TIME
# RubyProf.measure_mode = RubyProf::PROCESS_TIME
# RubyProf.measure_mode = RubyProf::ALLOCATIONS
RubyProf.measure_mode = RubyProf::MEMORY

SYMBOL_KEYS = { a: nil, b: 2 }
STRING_KEYS = { 'a' => 1, 'b' => '' }

RubyProf.start

Multiply.call(SYMBOL_KEYS)
Multiply.call(STRING_KEYS)

result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
