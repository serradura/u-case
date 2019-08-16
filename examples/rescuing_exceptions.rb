require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-service', '~> 0.12.0'
end

class Divide < Micro::Service::Base
  attributes :a, :b

  def call!
    return Failure('numbers must be greater than 0') if a < 0 || b < 0

    Success(a / b)
  rescue => e
    Failure(e.message)
  end
end

#---------------------------------#
puts "\n-- Success scenario --\n\n"
#---------------------------------#

result = Divide.call(a: 4, b: 2)

puts result.value if result.success?

#----------------------------------#
puts "\n-- Failure scenarios --\n\n"
#----------------------------------#

result = Divide.call(a: 4, b: 0)

puts result.value if result.failure?

puts ''

result = Divide.call(a: -4, b: 2)

puts result.value if result.failure?

# :: example of the output: ::

# -- Success scenario --
#
# 2
#
# -- Failure scenarios --
#
# divided by 0
#
# numbers must be greater than 0
