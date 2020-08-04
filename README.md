![Ruby](https://img.shields.io/badge/ruby-2.2+-ruby.svg?colorA=99004d&colorB=cc0066)
[![Gem](https://img.shields.io/gem/v/u-case.svg?style=flat-square)](https://rubygems.org/gems/u-case)
[![Build Status](https://travis-ci.com/serradura/u-case.svg?branch=master)](https://travis-ci.com/serradura/u-case)
[![Maintainability](https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/maintainability)](https://codeclimate.com/github/serradura/u-case/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/test_coverage)](https://codeclimate.com/github/serradura/u-case/test_coverage)

<img src="./assets/ucase_logo_v1.png" height="200" alt="u-case">

Create simple and powerful use cases as objects.

The main project goals are:
1. Easy to use and easy to learn (input **>>** process **>>** output).
2. Promote referential transparency (transforming instead of modifying) and data integrity.
3. No callbacks (e.g: before, after, around).
4. Solve complex business logic, by allowing the composition of use cases.
5. Be fast and optimized (Check out the [benchmarks](#benchmarks) section).

> Note: Check out the repo https://github.com/serradura/from-fat-controllers-to-use-cases to see a Rails application that uses this gem to handle its business logic.

## Documentation <!-- omit in toc -->

Version   | Documentation
--------- | -------------
3.0.0.rc4 | https://github.com/serradura/u-case/blob/master/README.md
2.6.0     | https://github.com/serradura/u-case/blob/v2.x/README.md
1.1.0     | https://github.com/serradura/u-case/blob/v1.x/README.md

## Table of Contents <!-- omit in toc -->
- [Required Ruby version](#required-ruby-version)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
  - [`Micro::Case` - How to define a use case?](#microcase---how-to-define-a-use-case)
  - [`Micro::Case::Result` - What is a use case result?](#microcaseresult---what-is-a-use-case-result)
    - [What are the default result types?](#what-are-the-default-result-types)
    - [How to define custom result types?](#how-to-define-custom-result-types)
    - [Is it possible to define a custom result type without a block?](#is-it-possible-to-define-a-custom-result-type-without-a-block)
    - [How to use the result hooks?](#how-to-use-the-result-hooks)
    - [Why the hook usage without a type exposes the result itself?](#why-the-hook-usage-without-a-type-exposes-the-result-itself)
      - [Using decomposition to access the result data and type](#using-decomposition-to-access-the-result-data-and-type)
    - [What happens if a result hook was declared multiple times?](#what-happens-if-a-result-hook-was-declared-multiple-times)
    - [How to use the `Micro::Case::Result#then` method?](#how-to-use-the-microcaseresultthen-method)
      - [What does happens when a `Micro::Case::Result#then` receives a block?](#what-does-happens-when-a-microcaseresultthen-receives-a-block)
      - [How to make attributes data injection using this feature?](#how-to-make-attributes-data-injection-using-this-feature)
  - [`Micro::Cases::Flow` - How to compose use cases?](#microcasesflow---how-to-compose-use-cases)
    - [Is it possible to compose a use case flow with other ones?](#is-it-possible-to-compose-a-use-case-flow-with-other-ones)
    - [Is it possible a flow accumulates its input and merges each success result to use as the argument of the next use cases?](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases)
    - [How to understand what is happening during a flow execution?](#how-to-understand-what-is-happening-during-a-flow-execution)
      - [`Micro::Case::Result#transitions` schema](#microcaseresulttransitions-schema)
      - [Is it possible disable the `Micro::Case::Result#transitions`?](#is-it-possible-disable-the-microcaseresulttransitions)
    - [Is it possible to declare a flow which includes the use case itself?](#is-it-possible-to-declare-a-flow-which-includes-the-use-case-itself)
  - [`Micro::Case::Strict` - What is a strict use case?](#microcasestrict---what-is-a-strict-use-case)
  - [`Micro::Case::Safe` - Is there some feature to auto handle exceptions inside of a use case or flow?](#microcasesafe---is-there-some-feature-to-auto-handle-exceptions-inside-of-a-use-case-or-flow)
    - [`Micro::Cases::Safe::Flow`](#microcasessafeflow)
    - [`Micro::Case::Result#on_exception`](#microcaseresulton_exception)
  - [`u-case/with_activemodel_validation` - How to validate use case attributes?](#u-casewith_activemodel_validation---how-to-validate-use-case-attributes)
    - [If I enabled the auto validation, is it possible to disable it only in specific use case classes?](#if-i-enabled-the-auto-validation-is-it-possible-to-disable-it-only-in-specific-use-case-classes)
    - [`Kind::Validator`](#kindvalidator)
- [`Micro::Case.config`](#microcaseconfig)
- [Benchmarks](#benchmarks)
  - [`Micro::Case` (v3.0.0)](#microcase-v300)
    - [Success results](#success-results)
    - [Failure results](#failure-results)
  - [`Micro::Cases::Flow` (v3.0.0)](#microcasesflow-v300)
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

1. [`kind`](https://github.com/serradura/kind) gem.

    A simple type system (at runtime) for Ruby.

    Used to validate method inputs using its [`activemodel validation`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) module is auto required by [`u-case/with_activemodel_validation`](#u-casewith_activemodel_validation---how-to-validate-use-case-attributes) mode, and expose `Kind::Of::Micro::Case`, `Kind::Of::Micro::Case::Result` type checkers.
2. [`u-attributes`](https://github.com/serradura/u-attributes) gem.

    This gem allows defining read-only attributes, that is, your objects will have only getters to access their attributes data.
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

    # 3. Wrap the use case result/output using the `Success(result: *)` or `Failure(result: *)` methods
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure result: { message: '`a` and `b` attributes must be numeric' }
    end
  end
end

#==========================#
# Calling a use case class #
#==========================#

# Success result

result = Multiply.call(a: 2, b: 2)

result.success? # true
result.data     # { number: 4 }

# Failure result

bad_result = Multiply.call(a: 2, b: '2')

bad_result.failure? # true
bad_result.data     # { message: "`a` and `b` attributes must be numeric" }

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
- `#use_case` returns the use case responsible for it. This feature is handy to handle a flow failure (this topic will be covered ahead).
- `#type` a Symbol which gives meaning for the result, this is useful to declare different types of failures or success.
- `#data` the result data itself.
- `#[]` and `#values_at` are shortcuts to access the `#data` values.
- `#on_success` or `#on_failure` are hook methods that help you to define the application flow.
- `#then` this method will allow applying a new use case if the current result was a success. The idea of this feature is to allow the creation of dynamic flows.
- `#transitions` returns an array with all of transformations wich a result [has during a flow](#how-to-understand-what-is-happening-during-a-flow-execution).

> **Note:** for backward compatibility, you could use the `#value` method as an alias of `#data` method.

[⬆️ Back to Top](#table-of-contents-)

#### What are the default result types?

Every result has a type and these are the defaults:
- `:ok` when success
- `:error`/`:exception` when failures

```ruby
class Divide < Micro::Case
  attributes :a, :b

  def call!
    if invalid_attributes.empty?
      Success result: { number: a / b }
    else
      Failure result: { invalid_attributes: invalid_attributes }
    end
  rescue => exception
    Failure result: exception
  end

  private def invalid_attributes
    attributes.select { |_key, value| !value.is_a?(Numeric) }
  end
end

# Success result

result = Divide.call(a: 2, b: 2)

result.type     # :ok
result.data     # { number: 1 }
result.success? # true
result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>2}, @a=2, @b=2, @__result=...>

# Failure result (type == :error)

bad_result = Divide.call(a: 2, b: '2')

bad_result.type     # :error
bad_result.data     # { invalid_attributes: { "b"=>"2" } }
bad_result.failure? # true
bad_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>"2"}, @a=2, @b="2", @__result=...>

# Failure result (type == :exception)

err_result = Divide.call(a: 2, b: 0)

err_result.type     # :exception
err_result.data     # { exception: <ZeroDivisionError: divided by 0> }
err_result.failure? # true
err_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>0}, @a=2, @b=0, @__result=#<Micro::Case::Result:0x0000 @use_case=#<Divide:0x0000 ...>, @type=:exception, @value=#<ZeroDivisionError: divided by 0>, @success=false>

# Note:
# ----
# Any Exception instance which is wrapped by
# the Failure(result: *) method will receive `:exception` instead of the `:error` type.
```

[⬆️ Back to Top](#table-of-contents-)

#### How to define custom result types?

Answer: Use a symbol as the argument of `Success()`, `Failure()` methods and declare the `result:` keyword to set the result data.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure :invalid_data, result: {
        attributes: attributes.reject { |_, input| input.is_a?(Numeric) }
      }
    end
  end
end

# Success result

result = Multiply.call(a: 3, b: 2)

result.type     # :ok
result.data     # { number: 6 }
result.success? # true

# Failure result

bad_result = Multiply.call(a: 3, b: '2')

bad_result.type     # :invalid_data
bad_result.data     # { attributes: {"b"=>"2"} }
bad_result.failure? # true
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to define a custom result type without a block?

Answer: Yes, it is possible. But this will have special behavior because the result data will be a hash with the given type as the key and true as its value.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure(:invalid_data)
    end
  end
end

result = Multiply.call(a: 2, b: '2')

result.failure?            # true
result.data                # { :invalid_data => true }
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
    return Failure :invalid, result: { msg: 'number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure :lte_zero, result: { msg: 'number must be greater than 0' } if number <= 0

    Success result: { number: number * 2 }
  end
end

#================================#
# Printing the output if success #
#================================#

Double
  .call(number: 3)
  .on_success { |result| p result[:number] }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# The output because it is a success:
#   6

#=============================#
# Raising an error if failure #
#=============================#

Double
  .call(number: -1)
  .on_success { |result| p result[:number] }
  .on_failure { |_result, use_case| puts "#{use_case.class.name} was the use case responsible for the failure" }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# The outputs will be:
#
# 1. Prints the message: Double was the use case responsible for the failure
# 2. Raises the exception: ArgumentError (the number must be greater than 0)

# Note:
# ----
# The use case responsible for the failure will be accessible as the second hook argument
```

#### Why the hook usage without a type exposes the result itself?

Answer: To allow you to define how to handle the program flow using some
conditional statement (like an `if`, `case/when`).

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure(:invalid) unless number.is_a?(Numeric)
    return Failure :lte_zero, result: attributes(:number) if number <= 0

    Success result: { number: number * 2 }
  end
end

Double
  .call(number: -1)
  .on_failure do |result, use_case|
    case result.type
    when :invalid then raise TypeError, "number must be a numeric value"
    when :lte_zero then raise ArgumentError, "number `#{result[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be the exception:
#
# ArgumentError (number `-1` must be greater than 0)
```

> **Note:** The same that was did in the previous examples could be done with `#on_success` hook!

##### Using decomposition to access the result data and type

The syntax to decompose an Array can be used in methods, blocks and assigments.
If you doesn't know it, check out the [Ruby doc](https://ruby-doc.org/core-2.2.0/doc/syntax/assignment_rdoc.html#label-Array+Decomposition).

```ruby
# The object exposed in the hook is a Micro::Case::Result, and it can be decomposed using this syntax. e.g:

Double
  .call(number: -2)
  .on_failure do |(data, type), use_case|
    case type
    when :invalid then raise TypeError, 'number must be a numeric value'
    when :lte_zero then raise ArgumentError, "number `#{data[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# The output will be the exception:
#
# ArgumentError (the number `-2` must be greater than 0)
```

> **Note:** The same that was did in the previous examples could be done with `#on_success` hook!

[⬆️ Back to Top](#table-of-contents-)

#### What happens if a result hook was declared multiple times?

Answer: The hook always will be triggered if it matches the result type.

```ruby
class Double < Micro::Case
  attributes :number

  def call!
    if number.is_a?(Numeric)
      Success :computed, result: { number: number * 2 }
    else
      Failure :invalid, result: { msg: 'number must be a numeric value' }
    end
  end
end

result = Double.call(number: 3)
result.data         # { number: 6 }
result[:number] * 4 # 24

accum = 0

result
  .on_success { |result| accum += result[:number] }
  .on_success { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }

accum # 24

result[:number] * 4 == accum # true
```

#### How to use the `Micro::Case::Result#then` method?

This method allows you to create dynamic flows, so, with it,
you can add new use cases or flows to continue the result transformation. e.g:

```ruby
class ForbidNegativeNumber < Micro::Case
  attribute :number

  def call!
    return Success result: attributes if number >= 0

    Failure result: attributes
  end
end

class Add3 < Micro::Case
  attribute :number

  def call!
    Success result: { number: number + 3 }
  end
end

result1 =
  ForbidNegativeNumber
    .call(number: -1)
    .then(Add3)

result1.data    # {'number' => -1}
result1.failure? # true

# ---

result2 =
  ForbidNegativeNumber
    .call(number: 1)
    .then(Add3)

result2.data     # {'number' => 4}
result2.success? # true
```

> **Note:** this method changes the [`Micro::Case::Result#transitions`](#how-to-understand-what-is-happening-during-a-flow-execution).

[⬆️ Back to Top](#table-of-contents-)

##### What does happens when a `Micro::Case::Result#then` receives a block?

It will yields self (a `Micro::Case::Result instance`) to the block and return the result of the block. e.g:

```ruby
class Add < Micro::Case
  attributes :a, :b

  def call!
    if Kind.of?(Numeric, a, b)
      Success result: { sum: a + b }
    else
      Failure(:attributes_arent_numbers)
    end
  end
end

# --

success_result =
  Add
    .call(a: 2, b: 2)
    .then { |result| result.success? ? result[:sum] : 0 }

puts success_result # 4

# --

failure_result =
  Add
    .call(a: 2, b: '2')
    .then { |result| result.success? ? result[:sum] : 0 }

puts failure_result # 0
```

[⬆️ Back to Top](#table-of-contents-)

##### How to make attributes data injection using this feature?

Pass a Hash as the second argument of the `Micro::Case::Result#then` method.

```ruby
Todo::FindAllForUser
  .call(user: current_user, params: params)
  .then(Paginate)
  .then(Serialize::PaginatedRelationAsJson, serializer: Todo::Serializer)
  .on_success { |result| render_json(200, data: result[:todos]) }
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Cases::Flow` - How to compose use cases?

In this case, this will be a **flow** (`Micro::Cases::Flow`).
The main idea of this feature is to use/reuse use cases as steps of a new use case.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

#-------------------------------------------#
# Creating a flow using Micro::Cases.flow() #
#-------------------------------------------#

Add2ToAllNumbers = Micro::Cases.flow([
  Steps::ConvertTextToNumbers,
  Steps::Add2
])

result = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

result.success? # true
result.data    # {:numbers => [3, 3, 4, 4, 5, 6]}

#---------------------------------------------------#
# An alternative way to create a flow using classes #
#---------------------------------------------------#

class DoubleAllNumbers < Micro::Case
  flow Steps::ConvertTextToNumbers,
       Steps::Double
end

DoubleAllNumbers.
  call(numbers: %w[1 1 b 2 3 4]).
  on_failure { |result| puts result[:message] } # "numbers must contain only numeric types"

# Note:
# ----
# When happening a failure, the use case responsible
# will be accessible in the result

result = DoubleAllNumbers.call(numbers: %w[1 1 b 2 3 4])

result.failure?                                    # true
result.use_case.is_a?(Steps::ConvertTextToNumbers) # true

result.on_failure do |_message, use_case|
  puts "#{use_case.class.name} was the use case responsible for the failure" # Steps::ConvertTextToNumbers was the use case responsible for the failure
end
```

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible to compose a use case flow with other ones?

Answer: Yes, it is possible.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

DoubleAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Double])

SquareAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Square])

DoubleAllNumbersAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, Steps::Add2])

SquareAllNumbersAndAdd2 =
  Micro::Cases.flow([SquareAllNumbers, Steps::Add2])

SquareAllNumbersAndDouble =
  Micro::Cases.flow([SquareAllNumbersAndAdd2, DoubleAllNumbers])

DoubleAllNumbersAndSquareAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, SquareAllNumbersAndAdd2])

SquareAllNumbersAndDouble
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 12, 12, 22, 36]

DoubleAllNumbersAndSquareAndAdd2
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 18, 18, 38, 66]
```

Note: You can blend any of the [available syntaxes/approaches](#how-to-create-a-flow-which-has-reusable-steps-to-define-a-complex-use-case) to create use case flows - [examples](https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/cases/flow/blend_test.rb#L5-L35).

[⬆️ Back to Top](#table-of-contents-)

#### Is it possible a flow accumulates its input and merges each success result to use as the argument of the next use cases?

Answer: Yes, it is possible! Look at the example below to understand how the data accumulation works inside of the flow execution.

```ruby
module Users
  class FindByEmail < Micro::Case
    attribute :email

    def call!
      user = User.find_by(email: email)

      return Success result: { user: user } if user

      Failure(:user_not_found)
    end
  end
end

module Users
  class ValidatePassword < Micro::Case::Strict
    attributes :user, :password

    def call!
      return Failure(:user_must_be_persisted) if user.new_record?
      return Failure(:wrong_password) if user.wrong_password?(password)

      return Success result: attributes(:user)
    end
  end
end

module Users
  Authenticate = Micro::Cases.flow([
    FindByEmail,
    ValidatePassword
  ])
end

Users::Authenticate
  .call(email: 'somebody@test.com', password: 'password')
  .on_success { |result| sign_in(result[:user]) }
  .on_failure(:wrong_password) { render status: 401 }
  .on_failure(:user_not_found) { render status: 404 }
```

First, lets see the attributes used by each use case:

```ruby
class Users::FindByEmail < Micro::Case
  attribute :email
end

class Users::ValidatePassword < Micro::Case
  attributes :user, :password
end
```

As you can see the `Users::ValidatePassword` expects a user as its input. So, how does it receives the user?
It receives the user from the `Users::FindByEmail` success result!

And this, is the power of use cases composition because the output
of one step will compose the input of the next use case in the flow!

> input **>>** process **>>** output

> **Note:** Check out these test examples [Micro::Cases::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/flow/result_transitions_test.rb) and [Micro::Cases::Safe::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/safe/flow/result_transitions_test.rb) to see different use cases sharing their own data.

[⬆️ Back to Top](#table-of-contents-)

#### How to understand what is happening during a flow execution?

Use `Micro::Case::Result#transitions`!

Let's use the [previous section example](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases) to ilustrate how to use this feature.

```ruby
user_authenticated =
  Users::Authenticate.call(email: 'rodrigo@test.com', password: user_password)

user_authenticated.transitions
[
  {
    :use_case => {
      :class      => Users::FindByEmail,
      :attributes => { :email => "rodrigo@test.com" }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password ]
  },
  {
    :use_case => {
      :class      => Users::ValidatePassword,
      :attributes => {
        :user     => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
        :password => "123456"
      }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password, :user ]
  }
]
```

The example above shows the output generated by the `Micro::Case::Result#transitions`.
With it is possible to analyze the use cases execution order and what were the given `inputs` (`[:attributes]`) and `outputs` (`[:success][:result]`) in the entire execution.

And look up the `accessible_attributes` property, it shows whats attributes are accessible in that flow step. For example, in the last step, you can see that the `accessible_attributes` increased because of the [data flow accumulation](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases).

> **Note:** The [`Micro::Case::Result#then`](#how-to-use-the-microcaseresultthen-method) increments the `Micro::Case::Result#transitions`.

##### `Micro::Case::Result#transitions` schema
```ruby
[
  {
    use_case: {
      class:      <Micro::Case>,# Use case which was executed
      attributes: <Hash>        # (Input) The use case's attributes
    },
    [success:, failure:] => {   # (Output)
      type:  <Symbol>,          # Result type. Defaults:
                                # Success = :ok, Failure = :error/:exception
      result: <Hash>            # The data returned by the use case
    },
    accessible_attributes: <Array>, # Properties that can be accessed by the use case's attributes,
                                    # starting with Hash used to invoke it and which are incremented
                                    # with each result value of the flow's use cases.
  }
]
```

##### Is it possible disable the `Micro::Case::Result#transitions`?

Answer: Yes, it is! You can use the `Micro::Case.config` to do this. [Link to](#microcaseconfig) this section.

#### Is it possible to declare a flow which includes the use case itself?

Answer: Yes, it is! You can use the `self.call!` macro. e.g:

```ruby
class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    Success result: { number: text.to_i }
  end
end

class ConvertNumberToText < Micro::Case
  attribute :number

  def call!
    Success result: { text: number.to_s }
  end
end

class Double < Micro::Case
  flow ConvertTextToNumber,
       self.call!,
       ConvertNumberToText

  attribute :number

  def call!
    Success result: { number: number * 2 }
  end
end

result = Double.call(text: '4')

result.success? # true
result[:number] # "8"

# NOTE: This feature can be used with the Micro::Case::Safe.
#       Checkout this test: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe/with_inner_flow_test.rb
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Strict` - What is a strict use case?

Answer: Is a use case which will require all the keywords (attributes) on its initialization.

```ruby
class Double < Micro::Case::Strict
  attribute :numbers

  def call!
    Success result: { numbers: numbers.map { |number| number * 2 } }
  end
end

Double.call({})

# The output will be the following exception:
# ArgumentError (missing keyword: :numbers)
```

[⬆️ Back to Top](#table-of-contents-)

### `Micro::Case::Safe` - Is there some feature to auto handle exceptions inside of a use case or flow?

Answer: Yes, there is one!

**Use cases:**

Like `Micro::Case::Strict` the `Micro::Case::Safe` is another kind of use case. It has the ability to auto intercept any exception as a failure result. e.g:

```ruby
require 'logger'

AppLogger = Logger.new(STDOUT)

class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    if a.is_a?(Integer) && b.is_a?(Integer)
      Success result: { number: a / b}
    else
      Failure(:not_an_integer)
    end
  end
end

result = Divide.call(a: 2, b: 0)
result.type == :exception                   # true
result.data                                 # { exception: #<ZeroDivisionError...> }
result[:exception].is_a?(ZeroDivisionError) # true

result.on_failure(:exception) do |result|
  AppLogger.error(result[:exception].message) # E, [2019-08-21T00:05:44.195506 #9532] ERROR -- : divided by 0
end

# Note:
# ----
# If you need to handle a specific error,
# I recommend the usage of a case statement. e,g:

result.on_failure(:exception) do |data, use_case|
  case exception = data[:exception]
  when ZeroDivisionError then AppLogger.error(exception.message)
  else AppLogger.debug("#{use_case.class.name} was the use case responsible for the exception")
  end
end

# Another note:
# ------------
# It is possible to rescue an exception even when is a safe use case.
# Examples: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe_test.rb#L90-L118
```

[⬆️ Back to Top](#table-of-contents-)

#### `Micro::Cases::Safe::Flow`

As the safe use cases, safe flows can intercept an exception in any of its steps. These are the ways to define one:

```ruby
module Users
  Create = Micro::Cases.safe_flow([
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
```

[⬆️ Back to Top](#table-of-contents-)

#### `Micro::Case::Result#on_exception`

In functional programming errors/exceptions are handled as regular data, the idea is to transform the output even when it happens an unexpected behavior. For many, [exceptions are very similar to the GOTO statement](https://softwareengineering.stackexchange.com/questions/189222/are-exceptions-as-control-flow-considered-a-serious-antipattern-if-so-why), jumping the application flow to paths which could be difficult to figure out how things work in a system.

To address this the `Micro::Case::Result` has a special hook `#on_exception` to helping you to handle the control flow in the case of exceptions.

> **Note**: this feature will work better if you use it with a `Micro::Case::Safe` use case/flow.

How does it work?

```ruby
class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    Success result: { division: a / b }
  end
end

Divide
  .call(a: 2, b: 0)
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Can't divide a number by 0
# Oh no, something went wrong!

Divide.
  .call(a: 2, b: '2').
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Please, use only numeric attributes.
# Oh no, something went wrong!
```

As you can see, this hook has the same behavior of `result.on_failure(:exception)`, but, the ideia here is to have a better communication in the code, making an explicit reference when some failure happened because of an exception.

[⬆️ Back to Top](#table-of-contents-)

### `u-case/with_activemodel_validation` - How to validate use case attributes?

**Requirement:**

To do this your application must have the [activemodel >= 3.2, < 6.1.0](https://rubygems.org/gems/activemodel) as a dependency.

```ruby
#
# By default, if your application has the activemodel as a dependency,
# any kind of use case can use it to validate their attributes.
#
class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    return Failure :validation_error, result: { errors: self.errors } if invalid?

    Success result: { number: a * b }
  end
end
```

But if do you want an automatic way to fail your use cases on validation errors, you can:

1. **require 'u-case/with_activemodel_validation'** mode

  ```ruby
  gem 'u-case', require: 'u-case/with_activemodel_validation'
  ```

2. Use the `Micro::Case.config` to enable it. [Link to](#microcaseconfig) this section.

Using this approach, you can rewrite the previous example with less code. e.g:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end

# Note:
# ----
# After requiring the validation mode, the
# Micro::Case::Strict and Micro::Case::Safe classes will inherit this new behavior.
```

#### If I enabled the auto validation, is it possible to disable it only in specific use case classes?

Answer: Yes, it is possible. To do this, you only need to use the `disable_auto_validation` macro. e.g:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  disable_auto_validation

  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end

Multiply.call(a: 2, b: 'a')

# The output will be the following exception:
# TypeError (String can't be coerced into Integer)
```

[⬆️ Back to Top](#table-of-contents-)

#### `Kind::Validator`

The [kind gem](https://github.com/serradura/kind) has a module to enable the validation of data type through [`ActiveModel validations`](https://guides.rubyonrails.org/active_model_basics.html#validations). So, when you require the `'u-case/with_activemodel_validation'`, this module will require the [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations).

The example below shows how to validate the attributes data types.

```ruby
class Todo::List::AddItem < Micro::Case
  attributes :user, :params

  validates :user, kind: User
  validates :params, kind: ActionController::Parameters

  def call!
    todo_params = params.require(:todo).permit(:title, :due_at)

    todo = user.todos.create(todo_params)

    Success result: { todo: todo }
  rescue ActionController::ParameterMissing => e
    Failure :parameter_missing, result: { message: e.message }
  end
end
```

[⬆️ Back to Top](#table-of-contents-)

## `Micro::Case.config`

The idea of this feature is to allow the configuration of some `u-case` features/modules.
I recommend you use it only once in your codebase. e.g. In a Rails initializer.

You can see below, which are all of the available configurations with their default values:

```ruby
Micro::Case.config do |config|
  # Use ActiveModel to auto-validate your use cases' attributes.
  config.enable_activemodel_validation = false

  # Use to enable/disable the `Micro::Case::Results#transitions` tracking.
  config.enable_transitions = true
end
```

[⬆️ Back to Top](#table-of-contents-)

## Benchmarks

### `Micro::Case` (v3.0.0)

#### Success results

| Gem / Abstraction      | Iterations per second |       Comparison  |
| -----------------      | --------------------: | ----------------: |
| Dry::Monads            |              139037.7 | _**The Fastest**_ |
| **Micro::Case**        |              101497.3 |     1.37x slower  |
| Interactor             |               30694.2 |     4.53x slower  |
| Trailblazer::Operation |               14580.8 |     9.54x slower  |
| Dry::Transaction       |                5728.0 |    24.27x slower  |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     3.056k i/100ms
# Trailblazer::Operation   1.480k i/100ms
#          Dry::Monads    14.316k i/100ms
#     Dry::Transaction   576.000  i/100ms
#          Micro::Case    10.388k i/100ms
#  Micro::Case::Strict     8.223k i/100ms
#    Micro::Case::Safe    10.057k i/100ms

# Calculating -------------------------------------
#           Interactor     30.694k (± 2.3%) i/s -    155.856k in   5.080475s
# Trailblazer::Operation   14.581k (± 3.9%) i/s -     74.000k in   5.083091s
#          Dry::Monads    139.038k (± 3.0%) i/s -    701.484k in   5.049921s
#     Dry::Transaction      5.728k (± 3.6%) i/s -     28.800k in   5.034599s
#          Micro::Case    100.712k (± 3.4%) i/s -    509.012k in   5.060139s
#  Micro::Case::Strict     81.513k (± 3.4%) i/s -    411.150k in   5.049962s
#    Micro::Case::Safe    101.497k (± 3.1%) i/s -    512.907k in   5.058463s

# Comparison:
#          Dry::Monads:   139037.7 i/s
#    Micro::Case::Safe:   101497.3 i/s - 1.37x  (± 0.00) slower
#          Micro::Case:   100711.6 i/s - 1.38x  (± 0.00) slower
#  Micro::Case::Strict:    81512.9 i/s - 1.71x  (± 0.00) slower
#           Interactor:    30694.2 i/s - 4.53x  (± 0.00) slower
# Trailblazer::Operation:  14580.8 i/s - 9.54x  (± 0.00) slower
#     Dry::Transaction:    5728.0 i/s - 24.27x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/master/benchmarks/use_case/with_success_result.rb

#### Failure results

| Gem / Abstraction      | Iterations per second |       Comparison  |
| -----------------      | --------------------: | ----------------: |
| **Micro::Case**        |               94619.6 | _**The Fastest**_ |
| Dry::Monads            |               70250.6 |     1.35x slower  |
| Trailblazer::Operation |               14786.1 |     6.40x slower  |
| Interactor             |               13770.0 |     6.87x slower  |
| Dry::Transaction       |                4994.4 |    18.95x slower  |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     1.408k i/100ms
# Trailblazer::Operation   1.492k i/100ms
#          Dry::Monads     7.224k i/100ms
#     Dry::Transaction   501.000  i/100ms
#          Micro::Case     9.664k i/100ms
#  Micro::Case::Strict     7.823k i/100ms
#    Micro::Case::Safe     9.464k i/100ms

# Calculating -------------------------------------
#           Interactor     13.770k (± 4.3%) i/s -     68.992k in   5.020330s
# Trailblazer::Operation   14.786k (± 5.3%) i/s -     74.600k in   5.064700s
#          Dry::Monads     70.251k (± 6.7%) i/s -    353.976k in   5.063010s
#     Dry::Transaction      4.994k (± 4.0%) i/s -     25.050k in   5.023997s
#          Micro::Case     94.620k (± 3.8%) i/s -    473.536k in   5.012483s
#  Micro::Case::Strict     76.059k (± 3.0%) i/s -    383.327k in   5.044482s
#    Micro::Case::Safe     91.719k (± 5.6%) i/s -    463.736k in   5.072552s

# Comparison:
#          Micro::Case:    94619.6 i/s
#    Micro::Case::Safe:    91719.4 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:    76058.7 i/s - 1.24x  (± 0.00) slower
#          Dry::Monads:    70250.6 i/s - 1.35x  (± 0.00) slower
# Trailblazer::Operation:  14786.1 i/s - 6.40x  (± 0.00) slower
#           Interactor:    13770.0 i/s - 6.87x  (± 0.00) slower
#     Dry::Transaction:    4994.4 i/s - 18.95x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/master/benchmarks/use_case/with_failure_result.rb

---

### `Micro::Cases::Flow` (v3.0.0)

| Gems / Abstraction      | [Success results](https://github.com/serradura/u-case/blob/master/benchmarks/flow/with_success_result.rb#L40) | [Failure results](https://github.com/serradura/u-case/blob/master/benchmarks/flow/with_failure_result.rb#L40) |
| ------------------------------------------- | ----------------: | ----------------: |
| Micro::Case internal flow (private methods) | _**The Fastest**_ | _**The Fastest**_ |
| Micro::Case `then` method                   |      1.48x slower |         0x slower |
| Micro::Cases.flow                           |      1.62x slower |      1.16x slower |
| Micro::Cases.safe_flow                      |      1.64x slower |      1.16x slower |
| Interactor::Organizer                       |      1.95x slower |      6.17x slower |

\* The `Dry::Monads`, `Dry::Transaction`, `Trailblazer::Operation` are out of this analysis because all of them doesn't have this kind of feature.

<details>
  <summary><strong>Success results</strong> - Show the full benchmark/ips results.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer                   5.219k i/100ms
# Micro::Cases.flow([])                   6.451k i/100ms
# Micro::Cases::safe_flow([])             6.421k i/100ms
# Micro::Case flow using `then` method    7.139k i/100ms
# Micro::Case flow using private methods 10.355k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer                    52.959k (± 1.7%) i/s -    266.169k in   5.027332s
# Micro::Cases.flow([])                    63.947k (± 1.7%) i/s -    322.550k in   5.045597s
# Micro::Cases::safe_flow([])              63.047k (± 3.1%) i/s -    321.050k in   5.097228s
# Micro::Case flow using `then` method     69.644k (± 4.0%) i/s -    349.811k in   5.031120s
# Micro::Case flow using private methods  103.297k (± 1.4%) i/s -    517.750k in   5.013254s

# Comparison:
# Micro::Case flow using private methods: 103297.4 i/s
# Micro::Case flow using `then` method:    69644.0 i/s - 1.48x  (± 0.00) slower
# Micro::Cases.flow([]):                   63946.7 i/s - 1.62x  (± 0.00) slower
# Micro::Cases::safe_flow([]):             63047.2 i/s - 1.64x  (± 0.00) slower
# Interactor::Organizer:                   52958.9 i/s - 1.95x  (± 0.00) slower
```
</details>

<details>
  <summary><strong>Failure results</strong> - Show the full benchmark/ips results.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer                  2.381k i/100ms
# Micro::Cases.flow([])                  12.003k i/100ms
# Micro::Cases::safe_flow([])            12.771k i/100ms
# Micro::Case flow using `then` method   15.085k i/100ms
# Micro::Case flow using private methods 14.254k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer                  23.579k (± 3.2%) i/s -    119.050k in   5.054410s
# Micro::Cases.flow([])                  124.072k (± 3.4%) i/s -    624.156k in   5.036618s
# Micro::Cases::safe_flow([])            124.894k (± 3.6%) i/s -    625.779k in   5.017494s
# Micro::Case flow using `then` method   145.370k (± 4.8%) i/s -    739.165k in   5.096972s
# Micro::Case flow using private methods 139.753k (± 5.6%) i/s -    698.446k in   5.015207s

# Comparison:
# Micro::Case flow using `then` method:   145369.7 i/s
# Micro::Case flow using private methods: 139753.4 i/s - same-ish: difference falls within error
# Micro::Cases::safe_flow([]):            124893.7 i/s - 1.16x  (± 0.00) slower
# Micro::Cases.flow([]):                  124071.8 i/s - 1.17x  (± 0.00) slower
# Interactor::Organizer:                  23578.7 i/s - 6.17x  (± 0.00) slower
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
