![Ruby](https://img.shields.io/badge/ruby-2.2+-ruby.svg?colorA=99004d&colorB=cc0066)
[![Gem](https://img.shields.io/gem/v/u-case.svg?style=flat-square)](https://rubygems.org/gems/u-case)
[![Build Status](https://travis-ci.com/serradura/u-case.svg?branch=master)](https://travis-ci.com/serradura/u-case)
[![Maintainability](https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/maintainability)](https://codeclimate.com/github/serradura/u-case/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/test_coverage)](https://codeclimate.com/github/serradura/u-case/test_coverage)

μ-case (Micro::Case) <!-- omit in toc -->
====================

Create simple and powerful use cases as objects.

The main project goals are:
1. Be simple to use and easy to learn (input **>>** process / transform **>>** output).
2. Promote referential transparency (transforming instead of modifying) and data integrity.
3. No callbacks (e.g: before, after, around).
4. Solve complex business logic, by allowing the composition of use cases.
5. Be fast and optimized (Check out the [benchmarks](#benchmarks) section).

> Note: Check out the repo https://github.com/serradura/from-fat-controllers-to-use-cases to see a Rails application that uses this gem to handle its business logic.

## Table of Contents <!-- omit in toc -->
- [Required Ruby version](#required-ruby-version)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
  - [Micro::Case - How to define a use case?](#microcase---how-to-define-a-use-case)
  - [Micro::Case::Result - What is a use case result?](#microcaseresult---what-is-a-use-case-result)
    - [What are the default result types?](#what-are-the-default-result-types)
    - [How to define custom result types?](#how-to-define-custom-result-types)
    - [Is it possible to define a custom result type without a block?](#is-it-possible-to-define-a-custom-result-type-without-a-block)
    - [How to use the result hooks?](#how-to-use-the-result-hooks)
    - [Why the failure hook (without a type) exposes a different kind of data?](#why-the-failure-hook-without-a-type-exposes-a-different-kind-of-data)
    - [What happens if a result hook was declared multiple times?](#what-happens-if-a-result-hook-was-declared-multiple-times)
    - [How to use the Micro::Case::Result#then method?](#how-to-use-the-microcaseresultthen-method)
  - [Micro::Case::Flow - How to compose use cases?](#microcaseflow---how-to-compose-use-cases)
    - [Is it possible to compose a use case flow with other ones?](#is-it-possible-to-compose-a-use-case-flow-with-other-ones)
    - [Is it possible a flow accumulates its input and merges each success result to use as the argument of their use cases?](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-their-use-cases)
    - [Is it possible to declare a flow which includes the use case itself?](#is-it-possible-to-declare-a-flow-which-includes-the-use-case-itself)
  - [Micro::Case::Strict - What is a strict use case?](#microcasestrict---what-is-a-strict-use-case)
  - [Micro::Case::Safe - Is there some feature to auto handle exceptions inside of a use case or flow?](#microcasesafe---is-there-some-feature-to-auto-handle-exceptions-inside-of-a-use-case-or-flow)
  - [u-case/with_validation - How to validate use case attributes?](#u-casewith_validation---how-to-validate-use-case-attributes)
    - [If I enabled the auto validation, is it possible to disable it only in specific use case classes?](#if-i-enabled-the-auto-validation-is-it-possible-to-disable-it-only-in-specific-use-case-classes)
- [Benchmarks](#benchmarks)
  - [Micro::Case](#microcase)
    - [Best overall](#best-overall)
    - [Success results](#success-results)
    - [Failure results](#failure-results)
  - [Micro::Case::Flow](#microcaseflow)
  - [Comparisons](#comparisons)
- [Examples](#examples)
  - [1️⃣ Rails App (API)](#1️⃣-rails-app-api)
  - [2️⃣ CLI calculator](#2️⃣-cli-calculator)
  - [3️⃣ Users creation](#3️⃣-users-creation)
  - [4️⃣ Rescuing exception inside of the use cases](#4️⃣-rescuing-exception-inside-of-the-use-cases)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Required Ruby version

> \>= 2.2.0

## Dependencies

This project depends on [Micro::Attribute](https://github.com/serradura/u-attributes) gem.
It is used to define the use case attributes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'u-case'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install u-case

## Usage

### `Micro::Case` - How to define a use case?

```ruby
class Multiply < Micro::Case
  # 1. Define its input as attributes
  attributes :a, :b

  # 2. Define the method `call!` with its business logic
  def call!

    # 3. Wrap the use case result/output using the `Success()` or `Failure()` methods
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success(a * b)
    else
      Failure { '`a` and `b` attributes must be numeric' }
    end
  end
end

#==========================#
# Calling a use case class #
#==========================#

# Success result

result = Multiply.call(a: 2, b: 2)

result.success? # true
result.value    # 4

# Failure result

bad_result = Multiply.call(a: 2, b: '2')

bad_result.failure? # true
bad_result.value    # "`a` and `b` attributes must be numeric"

#-----------------------------#
# Calling a use case instance #
#-----------------------------#

result = Multiply.new(a: 2, b: 3).call

result.value # 6

# Note:
# ----
# The result of a Micro::Case.call
# is an instance of Micro::Case::Result
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Result` - What is a use case result?

A `Micro::Case::Result` stores the use cases output data. These are their main methods:
- `#success?` returns true if is a successful result.
- `#failure?` returns true if is an unsuccessful result.
- `#value` the result value itself.
- `#type` a Symbol which gives meaning for the result, this is useful to declare different types of failures or success.
- `#on_success` or `#on_failure` are hook methods that help you define the application flow.
- `#use_case` if is a failure result, the use case responsible for it will be accessible through this method. This feature is handy to handle a flow failure (this topic will be covered ahead).
- `#then` allows if the current result is a success, the `then` method will allow to applying a new use case for its value.

[⬆️ Back to Top](#table-of-contents-)

#### What are the default result types?

Every result has a type and these are the defaults:
- `:ok` when success
- `:error`/`:exception` when failures

```ruby
class Divide < Micro::Case
  attributes :a, :b

  def call!
    invalid_attributes.empty? ? Success(a / b) : Failure(invalid_attributes)
  rescue => e
    Failure(e)
  end

  private def invalid_attributes
    attributes.select { |_key, value| !value.is_a?(Numeric) }
  end
end

# Success result

result = Divide.call(a: 2, b: 2)

result.type     # :ok
result.value    # 1
result.success? # true
result.use_case # raises `Micro::Case::Error::InvalidAccessToTheUseCaseObject: only a failure result can access its own use case`

# Failure result (type == :error)

bad_result = Divide.call(a: 2, b: '2')

bad_result.type     # :error
bad_result.value    # {"b"=>"2"}
bad_result.failure? # true
bad_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>"2"}, @a=2, @b="2", @__result=#<Micro::Case::Result:0x0000 @use_case=#<Divide:0x0000 ...>, @type=:error, @value={"b"=>"2"}, @success=false>>

# Failure result (type == :exception)

err_result = Divide.call(a: 2, b: 0)

err_result.type     # :exception
err_result.value    # <ZeroDivisionError: divided by 0>
err_result.failure? # true
err_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>0}, @a=2, @b=0, @__result=#<Micro::Case::Result:0x0000 @use_case=#<Divide:0x0000 ...>, @type=:exception, @value=#<ZeroDivisionError: divided by 0>, @success=false>>

# Note:
# ----
# Any Exception instance which is wrapped by
# the Failure() method will receive `:exception` instead of the `:error` type.
```

[⬆️ Back to Top](#table-of-contents-)

#### How to define custom result types?

Answer: Use a symbol as the argument of `Success()`, `Failure()` methods and declare a block to set their values.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    return Success(a * b) if a.is_a?(Numeric) && b.is_a?(Numeric)

    Failure(:invalid_data) do
      attributes.reject { |_, input| input.is_a?(Numeric) }
    end
  end
end

# Success result

result = Multiply.call(a: 3, b: 2)

result.type     # :ok
result.value    # 6
result.success? # true

# Failure result

bad_result = Multiply.call(a: 3, b: '2')

bad_result.type     # :invalid_data
bad_result.value    # {"b"=>"2"}
bad_result.failure? # true
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to define a custom result type without a block?

Answer: Yes, it is. But only for failure results!

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    return Failure(:invalid_data) unless a.is_a?(Numeric) && b.is_a?(Numeric)

    Success(a * b)
  end
end

result = Multiply.call(a: 2, b: '2')

result.failure?            # true
result.value               # :invalid_data
result.type                # :invalid_data
result.use_case.attributes # {"a"=>2, "b"=>"2"}

# Note:
# ----
# This feature is handy to handle failures in a flow
# (this topic will be covered ahead).
```

[⬆️ Back to Top](#table-of-contents-)

#### How to use the result hooks?

As mentioned earlier, the `Micro::Case::Result` has two methods to improve the flow control. They are: `#on_success`, `on_failure`.

The examples below show how to use them:

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure(:invalid) { 'the number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure(:lte_zero) { 'the number must be greater than 0' } if number <= 0

    Success(number * 2)
  end
end

#================================#
# Printing the output if success #
#================================#

Double
  .call(number: 3)
  .on_success { |number| p number }
  .on_failure(:invalid) { |msg| raise TypeError, msg }
  .on_failure(:lte_zero) { |msg| raise ArgumentError, msg }

# The output because it is a success:
#   6

#=============================#
# Raising an error if failure #
#=============================#

Double
  .call(number: -1)
  .on_success { |number| p number }
  .on_failure { |_result, use_case| puts "#{use_case.class.name} was the use case responsible for the failure" }
  .on_failure(:invalid) { |msg| raise TypeError, msg }
  .on_failure(:lte_zero) { |msg| raise ArgumentError, msg }

# The outputs will be:
#
# 1. Prints the message: Double was the use case responsible for the failure
# 2. Raises the exception: ArgumentError (the number must be greater than 0)

# Note:
# ----
# The use case responsible for the failure will be accessible as the second hook argument
```

#### Why the failure hook (without a type) exposes a different kind of data?

Answer: To allow you to define how to handle the program flow using some
conditional statement (like an `if`, `case/when`).

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure(:invalid) unless number.is_a?(Numeric)
    return Failure(:lte_zero) { number } if number <= 0

    Success(number * 2)
  end
end

#=================================#
# Using the result type and value #
#=================================#

Double
  .call(-1)
  .on_failure do |result, use_case|
    case result.type
    when :invalid then raise TypeError, 'the number must be a numeric value'
    when :lte_zero then raise ArgumentError, "the number `#{result.value}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be the exception:
#
# ArgumentError (the number `-1` must be greater than 0)

#=====================================================#
# Using decomposition to access result value and type #
#=====================================================#

# The syntax to decompose an Array can be used in methods, blocks and assigments.
# If you doesn't know that, check out:
# https://ruby-doc.org/core-2.2.0/doc/syntax/assignment_rdoc.html#label-Array+Decomposition
#
# And the object exposed in the hook failure can be decomposed using this syntax. e.g:

Double
  .call(-2)
  .on_failure do |(value, type), use_case|
    case type
    when :invalid then raise TypeError, 'the number must be a numeric value'
    when :lte_zero then raise ArgumentError, "the number `#{value}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be the exception:
#
# ArgumentError (the number `-2` must be greater than 0)
```

[⬆️ Back to Top](#table-of-contents-)

#### What happens if a result hook was declared multiple times?

Answer: The hook always will be triggered if it matches the result type.

```ruby
class Double < Micro::Case
  attributes :number

  def call!
    return Failure(:invalid) { 'the number must be a numeric value' } unless number.is_a?(Numeric)

    Success(:computed) { number * 2 }
  end
end

result = Double.call(number: 3)
result.value     # 6
result.value * 4 # 24

accum = 0

result.on_success { |number| accum += number }
      .on_success { |number| accum += number }
      .on_success(:computed) { |number| accum += number }
      .on_success(:computed) { |number| accum += number }

accum # 24

result.value * 4 == accum # true
```

#### How to use the `Micro::Case::Result#then` method?

```ruby
class ForbidNegativeNumber < Micro::Case
  attribute :number

  def call!
    return Success { attributes } if number >= 0

    Failure { attributes }
  end
end

class Add3 < Micro::Case
  attribute :number

  def call!
    Success { { number: number + 3 } }
  end
end

result1 =
  ForbidNegativeNumber
    .call(number: -1)
    .then(Add3)

result1.type     # :error
result1.value    # {'number' => -1}
result1.failure? # true

# ---

result2 =
  ForbidNegativeNumber
    .call(number: 1)
    .then(Add3)

result2.type     # :ok
result2.value    # {'number' => 4}
result2.success? # true
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Flow` - How to compose use cases?

In this case, this will be a **flow** (`Micro::Case::Flow`).
The main idea of this feature is to use/reuse use cases as steps of a new use case.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure('numbers must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * 2 })
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * number })
    end
  end
end

#---------------------------------------------#
# Creating a flow using the collection syntax #
#---------------------------------------------#

Add2ToAllNumbers = Micro::Case::Flow([
  Steps::ConvertTextToNumbers,
  Steps::Add2
])

result = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

p result.success? # true
p result.value    # {:numbers => [3, 3, 4, 4, 5, 6]}

#---------------------------------------------------#
# An alternative way to create a flow using classes #
#---------------------------------------------------#

class DoubleAllNumbers < Micro::Case
  flow Steps::ConvertTextToNumbers,
       Steps::Double
end

DoubleAllNumbers
  .call(numbers: %w[1 1 b 2 3 4])
  .on_failure { |message| p message } # "numbers must contain only numeric types"

# !------------------------------------ ! #
# ! Deprecated: Micro::Case::Flow mixin ! #
# !-------------------------------------! #

# The code below still works, but it will output a warning message:
# Deprecation: Micro::Case::Flow mixin is being deprecated, please use `Micro::Case` inheritance instead.

class DoubleAllNumbers
  include Micro::Case::Flow

  flow Steps::ConvertTextToNumbers,
       Steps::Double
end

# Note: This feature will be removed in the next major release (3.0)

#-------------------------------------------------------------#
# Another way to create a flow using the composition operator #
#-------------------------------------------------------------#

SquareAllNumbers =
  Steps::ConvertTextToNumbers >> Steps::Square

SquareAllNumbers
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [1, 1, 4, 4, 9, 16]

# Note:
# ----
# When happening a failure, the use case responsible
# will be accessible in the result

result = SquareAllNumbers.call(numbers: %w[1 1 b 2 3 4])

result.failure?                                # true
result.use_case.is_a?(Steps::ConvertTextToNumbers) # true

result.on_failure do |_message, use_case|
  puts "#{use_case.class.name} was the use case responsible for the failure" # Steps::ConvertTextToNumbers was the use case responsible for the failure
end
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to compose a use case flow with other ones?

Answer: Yes, it is.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success(numbers: numbers.map(&:to_i))
      else
        Failure('numbers must contain only numeric types')
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number + 2 })
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * 2 })
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success(numbers: numbers.map { |number| number * number })
    end
  end
end

Add2ToAllNumbers = Steps::ConvertTextToNumbers >> Steps::Add2
DoubleAllNumbers = Steps::ConvertTextToNumbers >> Steps::Double
SquareAllNumbers = Steps::ConvertTextToNumbers >> Steps::Square

DoubleAllNumbersAndAdd2 = DoubleAllNumbers >> Steps::Add2
SquareAllNumbersAndAdd2 = SquareAllNumbers >> Steps::Add2

SquareAllNumbersAndDouble = SquareAllNumbersAndAdd2 >> DoubleAllNumbers
DoubleAllNumbersAndSquareAndAdd2 = DoubleAllNumbers >> SquareAllNumbersAndAdd2

SquareAllNumbersAndDouble
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [6, 6, 12, 12, 22, 36]

DoubleAllNumbersAndSquareAndAdd2
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |value| p value[:numbers] } # [6, 6, 18, 18, 38, 66]
```

Note: You can blend any of the [available syntaxes/approaches](#how-to-create-a-flow-which-has-reusable-steps-to-define-a-complex-use-case) to create use case flows - [examples](https://github.com/serradura/u-case/blob/master/test/micro/case/flow/blend_test.rb#L7-L34).

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible a flow accumulates its input and merges each success result to use as the argument of their use cases?

Answer: Yes, it is! Check out these test examples [Micro::Case::Flow](https://github.com/serradura/u-case/blob/e0066d8a6e3a9404069dfcb9bf049b854f08a33c/test/micro/case/flow/reducer_test.rb) and [Micro::Case::Safe::Flow](https://github.com/serradura/u-case/blob/e0066d8a6e3a9404069dfcb9bf049b854f08a33c/test/micro/case/safe/flow/reducer_test.rb) to see different use cases sharing their own data.

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to declare a flow which includes the use case itself?

Answer: Yes, it is! You can use the `self.call!` macro. e.g:

```ruby
class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    Success { { number: text.to_i } }
  end
end

class ConvertNumberToText < Micro::Case
  attribute :number

  def call!
    Success { { text: number.to_s } }
  end
end

class Double < Micro::Case
  flow ConvertTextToNumber,
       self.call!,
       ConvertNumberToText

  attribute :number

  def call!
    Success { { number: number * 2 } }
  end
end

result = Double.call(text: '4')

result.success? # true
result.value    # "8"

# NOTE: This feature can be used with the Micro::Case::Safe.
#       Checkout the test: test/micro/case/safe/flow/with_classes/using_itself_test.rb
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Strict` - What is a strict use case?

Answer: Is a use case which will require all the keywords (attributes) on its initialization.

```ruby
class Double < Micro::Case::Strict
  attribute :numbers

  def call!
    Success(numbers.map { |number| number * 2 })
  end
end

Double.call({})

# The output will be the following exception:
# ArgumentError (missing keyword: :numbers)
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Safe` - Is there some feature to auto handle exceptions inside of a use case or flow?

Answer: Yes, there is!

**Use cases:**

Like `Micro::Case::Strict` the `Micro::Case::Safe` is another kind of use case. It has the ability to auto intercept any exception as a failure result. e.g:

```ruby
require 'logger'

AppLogger = Logger.new(STDOUT)

class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    return Success(a / b) if a.is_a?(Integer) && b.is_a?(Integer)
    Failure(:not_an_integer)
  end
end

result = Divide.call(a: 2, b: 0)
result.type == :exception             # true
result.value.is_a?(ZeroDivisionError) # true

result.on_failure(:exception) do |exception|
  AppLogger.error(exception.message) # E, [2019-08-21T00:05:44.195506 #9532] ERROR -- : divided by 0
end

# Note:
# ----
# If you need to handle a specific error,
# I recommend the usage of a case statement. e,g:

result.on_failure(:exception) do |exception, use_case|
  case exception
  when ZeroDivisionError then AppLogger.error(exception.message)
  else AppLogger.debug("#{use_case.class.name} was the use case responsible for the exception")
  end
end

# Another note:
# ------------
# It is possible to rescue an exception even when is a safe use case.
# Examples: https://github.com/serradura/u-case/blob/5a85fc238b63811a32737493dc6c59965f92491d/test/micro/case/safe_test.rb#L95-L123
```

**Flows:**

As the safe use cases, safe flows can intercept an exception in any of its steps. These are the ways to define one:

```ruby
module Users
  Create = ProcessParams & ValidateParams & Persist & SendToCRM
end

# Note:
# The ampersand is based on the safe navigation operator. https://ruby-doc.org/core-2.6/doc/syntax/calling_methods_rdoc.html#label-Safe+navigation+operator

# The alternatives to declare a safe flow are:

module Users
  Create = Micro::Case::Safe::Flow([
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ])
end

# or within classes

module Users
  class Create < Micro::Case::Safe
    flow ProcessParams,
         ValidateParams,
         Persist,
         SendToCRM
  end
end


# !------------------------------------------ ! #
# ! Deprecated: Micro::Case::Safe::Flow mixin ! #
# !-------------------------------------------! #

# The code below still works, but it will output a warning message:
# Deprecation: Micro::Case::Flow mixin is being deprecated, please use `Micro::Case` inheritance instead.

module Users
  class Create
    include Micro::Case::Safe::Flow

    flow ProcessParams, ValidateParams, Persist, SendToCRM
  end
end

# Note: This feature will be removed in the next major release (3.0)
```

[⬆️ Back to Top](#table-of-contents-)

### `u-case/with_validation` - How to validate use case attributes?

**Requirement:**

To do this your application must have the [activemodel >= 3.2](https://rubygems.org/gems/activemodel) as a dependency.

```ruby
#
# By default, if your application has the activemodel as a dependency,
# any kind of use case can use it to validate their attributes.
#
class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    return Failure(:validation_error) { {errors: self.errors} } unless valid?

    Success(number: a * b)
  end
end

#
# But if do you want an automatic way to fail
# your use cases on validation errors, you can use:

# In some file. e.g: A Rails initializer
require 'u-case/with_validation' # or require 'micro/case/with_validation'

# In the Gemfile
gem 'u-case', require: 'u-case/with_validation'

# Using this approach, you can rewrite the previous example with less code. e.g:

class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    Success(number: a * b)
  end
end

# Note:
# ----
# After requiring the validation mode, the
# Micro::Case::Strict and Micro::Case::Safe classes will inherit this new behavior.
```

#### If I enabled the auto validation, is it possible to disable it only in specific use case classes?

Answer: Yes, it is. To do this, you only need to use the `disable_auto_validation` macro. e.g:

```ruby
require 'u-case/with_validation'

class Multiply < Micro::Case
  disable_auto_validation

  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    Success(number: a * b)
  end
end

Multiply.call(a: 2, b: 'a')

# The output will be the following exception:
# TypeError (String can't be coerced into Integer)
```

[⬆️ Back to Top](#table-of-contents-)

## Benchmarks

### `Micro::Case`

#### Best overall

The table below contains the average between the [Success results](#success-results) and [Failure results](#failure-results) benchmarks.

| Gem / Abstraction      | Iterations per second |       Comparison |
| ---------------------- | --------------------: | ---------------: |
| **Micro::Case**        |              116629.7 | _**The Faster**_ |
| Dry::Monads            |              101796.3 |     1.14x slower |
| Interactor             |               21230.5 |     5.49x slower |
| Trailblazer::Operation |               16466.6 |     7.08x slower |
| Dry::Transaction       |                5069.5 |    23.00x slower |

---

#### Success results

| Gem / Abstraction      | Iterations per second |       Comparison |
| -----------------      | --------------------: | ---------------: |
| Dry::Monads            |              139352.5 | _**The Faster**_ |
| **Micro::Case**        |              124749.4 |     1.12x slower |
| Interactor             |               28974.4 |     4.81x slower |
| Trailblazer::Operation |               17275.6 |     8.07x slower |
| Dry::Transaction       |                5571.7 |    25.01x slower |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

  ```ruby
  # Warming up --------------------------------------
  #           Interactor     2.865k i/100ms
  # Trailblazer::Operation
  #                          1.686k i/100ms
  #          Dry::Monads    13.389k i/100ms
  #     Dry::Transaction   551.000  i/100ms
  #          Micro::Case    11.984k i/100ms
  #  Micro::Case::Strict     9.102k i/100ms
  #    Micro::Case::Safe    11.747k i/100ms
  # Calculating -------------------------------------
  #           Interactor     28.974k (± 2.7%) i/s -    146.115k in   5.046703s
  # Trailblazer::Operation
  #                          17.276k (± 1.8%) i/s -     87.672k in   5.076609s
  #          Dry::Monads    139.353k (± 2.5%) i/s -    709.617k in   5.095599s
  #     Dry::Transaction      5.572k (± 3.6%) i/s -     28.101k in   5.050376s
  #          Micro::Case    124.749k (± 1.9%) i/s -    635.152k in   5.093310s
  #  Micro::Case::Strict     93.417k (± 4.8%) i/s -    473.304k in   5.081341s
  #    Micro::Case::Safe    120.607k (± 3.2%) i/s -    610.844k in   5.070394s

  # Comparison:
  #          Dry::Monads:   139352.5 i/s
  #          Micro::Case:   124749.4 i/s - 1.12x  slower
  #    Micro::Case::Safe:   120607.3 i/s - 1.16x  slower
  #  Micro::Case::Strict:    93417.3 i/s - 1.49x  slower
  #           Interactor:    28974.4 i/s - 4.81x  slower
  # Trailblazer::Operation:  17275.6 i/s - 8.07x  slower
  #     Dry::Transaction:     5571.7 i/s - 25.01x  slower
  ```
</details>

https://github.com/serradura/u-case/blob/master/benchmarks/use_case/with_success_result.rb

#### Failure results

| Gem / Abstraction      | Iterations per second |       Comparison |
| -----------------      | --------------------: | ---------------: |
| **Micro::Case**        |              108510.0 | _**The Faster**_ |
| Dry::Monads            |               64240.1 |     1.69x slower |
| Trailblazer::Operation |               15657.7 |     6.93x slower |
| Interactor             |               13486.7 |     8.05x slower |
| Dry::Transaction       |                4567.3 |    23.76x slower |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

  ```ruby
  # Warming up --------------------------------------
  #           Interactor     1.331k i/100ms
  # Trailblazer::Operation
  #                          1.544k i/100ms
  #          Dry::Monads     6.343k i/100ms
  #     Dry::Transaction   456.000  i/100ms
  #          Micro::Case    10.429k i/100ms
  #  Micro::Case::Strict     8.109k i/100ms
  #    Micro::Case::Safe    10.280k i/100ms
  # Calculating -------------------------------------
  #           Interactor     13.487k (± 1.9%) i/s -     67.881k in   5.035059s
  # Trailblazer::Operation
  #                          15.658k (± 1.6%) i/s -     78.744k in   5.030427s
  #          Dry::Monads     64.240k (± 1.8%) i/s -    323.493k in   5.037461s
  #     Dry::Transaction      4.567k (± 1.3%) i/s -     23.256k in   5.092699s
  #          Micro::Case    108.510k (± 2.3%) i/s -    542.308k in   5.000605s
  #  Micro::Case::Strict     83.527k (± 1.4%) i/s -    421.668k in   5.049245s
  #    Micro::Case::Safe    105.641k (± 3.7%) i/s -    534.560k in   5.067836s

  # Comparison:
  #          Micro::Case:   108510.0 i/s
  #    Micro::Case::Safe:   105640.6 i/s - same-ish: difference falls within error
  #  Micro::Case::Strict:    83526.8 i/s - 1.30x  slower
  #          Dry::Monads:    64240.1 i/s - 1.69x  slower
  # Trailblazer::Operation:  15657.7 i/s - 6.93x  slower
  #           Interactor:    13486.7 i/s - 8.05x  slower
  #     Dry::Transaction:     4567.3 i/s - 23.76x  slower
  ```
</details>

https://github.com/serradura/u-case/blob/master/benchmarks/use_case/with_failure_result.rb

---

### `Micro::Case::Flow`

| Gems / Abstraction      | [Success results](https://github.com/serradura/u-case/blob/master/benchmarks/flow/with_success_result.rb#L40) | [Failure results](https://github.com/serradura/u-case/blob/master/benchmarks/flow/with_failure_result.rb#L40) |
| ------------------      | ---------------: | ---------------: |
| Micro::Case::Flow       | _**The Faster**_ | _**The Faster**_ |
| Micro::Case::Safe::Flow |        0x slower |        0x slower |
| Interactor::Organizer   |     1.47x slower |     5.51x slower |

\* The `Dry::Monads`, `Dry::Transaction`, `Trailblazer::Operation` are out of this analysis because all of them doesn't have this kind of feature.

<details>
  <summary><strong>Success results</strong> - Show the full benchmark/ips results.</summary>

  ```ruby
  # Warming up --------------------------------------
  #   Interactor::Organizer  4.880k i/100ms
  #       Micro::Case::Flow  7.035k i/100ms
  # Micro::Case::Safe::Flow  7.059k i/100ms

  # Calculating -------------------------------------
  #   Interactor::Organizer  50.208k (± 1.3%) i/s -    253.760k in   5.055099s
  #       Micro::Case::Flow  73.791k (± 0.9%) i/s -    372.855k in   5.053311s
  # Micro::Case::Safe::Flow  73.314k (± 1.1%) i/s -    367.068k in   5.007473s

  # Comparison:
  #       Micro::Case::Flow: 73790.7 i/s
  # Micro::Case::Safe::Flow: 73313.7 i/s - same-ish: difference falls within error
  #   Interactor::Organizer: 50207.7 i/s - 1.47x  slower
  ```
</details>

<details>
  <summary><strong>Failure results</strong> - Show the full benchmark/ips results.</summary>

  ```ruby
  # Warming up --------------------------------------
  #   Interactor::Organizer   2.372k i/100ms
  #       Micro::Case::Flow   12.802k i/100ms
  # Micro::Case::Safe::Flow   12.673k i/100ms

  # Calculating -------------------------------------
  #   Interactor::Organizer   24.522k (± 2.0%) i/s -    123.344k in   5.032159s
  #       Micro::Case::Flow   135.122k (± 1.7%) i/s -    678.506k in   5.022903s
  # Micro::Case::Safe::Flow   133.980k (± 1.4%) i/s -    671.669k in   5.014181s

  # Comparison:
  #       Micro::Case::Flow:   135122.0 i/s
  # Micro::Case::Safe::Flow:   133979.8 i/s - same-ish: difference falls within error
  #   Interactor::Organizer:   24521.8 i/s - 5.51x  slower
  ```
</details>

https://github.com/serradura/u-case/tree/master/benchmarks/flow

### Comparisons

Check it out implementations of the same use case with different gems/abstractions.

* [interactor](https://github.com/serradura/u-case/blob/master/comparisons/interactor.rb)
* [u-case](https://github.com/serradura/u-case/blob/master/comparisons/u-case.rb)

[⬆️ Back to Top](#table-of-contents-)

## Examples

### 1️⃣ Rails App (API)

> This project shows different kinds of architecture (one per commit), and in the last one, how to use the Micro::Case gem to handle the application business logic.
>
> Link: https://github.com/serradura/from-fat-controllers-to-use-cases

### 2️⃣ CLI calculator

> Rake tasks to demonstrate how to handle user data, and how to use different failure types to control the program flow.
>
> Link: https://github.com/serradura/u-case/tree/master/examples/calculator

### 3️⃣ Users creation

> An example of a use case flow that define steps to sanitize, validate, and persist its input data.
>
> Link: https://github.com/serradura/u-case/blob/master/examples/users_creation.rb

### 4️⃣ Rescuing exception inside of the use cases

> Link: https://github.com/serradura/u-case/blob/master/examples/rescuing_exceptions.rb

[⬆️ Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `./test.sh` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-case. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Micro::Case project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-case/blob/master/CODE_OF_CONDUCT.md).
