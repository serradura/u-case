require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'u-case', '~> 3.0.0.rc4'
end

class DivideV1 < Micro::Case
  attributes :a, :b

  def call!
    return Success result: { division: a / b } if a > 0 && b > 0

    Failure result: { message: 'numbers must be greater than 0' }
  rescue => e
    Failure(e)
  end
end

class DivideV2 < Micro::Case::Safe
  attributes :a, :b

  def call!
    return Success result: { division: a / b } if a > 0 && b > 0

    Failure result: { message: 'numbers must be greater than 0' }
  end
end

#-------------------------#
puts "\n== DivideV1 ==\n"
#-------------------------#

#---------------------------------#
puts "\n-- Success scenario --\n\n"
#---------------------------------#

result = DivideV1.call(a: 4, b: 2)

p result.data if result.success?

#----------------------------------#
puts "\n-- Failure scenarios --\n\n"
#----------------------------------#

result = DivideV1.call(a: 4, b: 0)

p result.data if result.failure?

puts ''

result = DivideV1.call(a: -4, b: 2)

p result.data if result.failure?

#
# ---
#

#-------------------------#
puts "\n== DivideV2 ==\n"
#-------------------------#

#---------------------------------#
puts "\n-- Success scenario --\n\n"
#---------------------------------#

result = DivideV2.call(a: 4, b: 2)

puts result.value if result.success?

#----------------------------------#
puts "\n-- Failure scenarios --\n\n"
#----------------------------------#

result = DivideV2.call(a: 4, b: 0)

p result.value if result.failure?

puts ''

result = DivideV2.call(a: -4, b: 2)

p result.value if result.failure?

# :: example of the outputs ::

# -- Success scenario --
#
# 2
#
# -- Failure scenarios --
#
# #<ZeroDivisionError: divided by 0>
#
# numbers must be greater than 0
