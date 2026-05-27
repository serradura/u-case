# μ-case — test doubles example

This example shows how to use `u-case`'s native test-double factories —
`Micro::Case::Result::Success.new`, `Micro::Case::Result::Failure.new`,
and their `.to_yield` companions — to fabricate result instances in tests
**without running a real use case**.

The factories are opt-in: the gem does not auto-require them. Add a
single line to your test/spec helper:

```ruby
# spec/spec_helper.rb  OR  test/test_helper.rb
require 'micro/case/with_test_doubles'
```

## What's in here

```
examples/test_doubles/
├── lib/
│   └── affiliates.rb               # FetchEmail, SendInvite, DeliverReferral
├── spec/                           # RSpec, return-value + block-form stubbing
│   ├── spec_helper.rb
│   ├── send_invite_spec.rb
│   └── deliver_referral_spec.rb
└── test/                           # Minitest + Mocha, same scenarios
    ├── test_helper.rb
    ├── send_invite_test.rb
    └── deliver_referral_test.rb
```

`Affiliates::FetchEmail` is the collaborator. The consumers
`Affiliates::SendInvite` and `Affiliates::DeliverReferral` each receive
it through an attribute, which is what lets the tests swap it for a stub.

## Two stubbing shapes

### 1. Return-value stubbing — `Result::Success.new` / `Result::Failure.new`

When the consumer reads the collaborator's return value directly
(`result = service.call(...); result.success?`):

```ruby
# RSpec
allow(fetch_email_service).to receive(:call)
  .with(id: 1)
  .and_return(Micro::Case::Result::Success.new(data: { email: 'a@b.c' }))
```

```ruby
# Minitest + Mocha
fetch_email_service
  .stubs(:call)
  .with(id: 1)
  .returns(Micro::Case::Result::Success.new(data: { email: 'a@b.c' }))
```

The fabricated result is a plain `Micro::Case::Result` instance —
`result.class == Micro::Case::Result`, `result.success?`, pattern
matching, `result[:email]`, `result.type`, and `result.use_case` all
behave exactly like a result returned by a real use case.

### 2. Block-form stubbing — `Result::Success.to_yield` / `Result::Failure.to_yield`

When the consumer uses the block form
(`service.call(...) { |on| on.success { ... }; on.failure { ... } }`):

```ruby
# RSpec
allow(fetch_email_service).to receive(:call)
  .with(id: 1)
  .and_yield(Micro::Case::Result::Success.to_yield(data: { email: 'a@b.c' }))
```

```ruby
# Minitest + Mocha
fetch_email_service
  .stubs(:call)
  .with(id: 1)
  .yields(Micro::Case::Result::Success.to_yield(data: { email: 'a@b.c' }))
```

`.to_yield` returns a `Micro::Case::Result::Wrapper` in the initial
state — the same wrapper instance type `Micro::Case.call(input) { |on| ... }`
yields internally — so `on.success` / `on.failure` inside the block
behave exactly as they would against a real wrapper.

## Running

```sh
bundle install

# Minitest + Mocha
bundle exec rake test

# RSpec
bundle exec rspec spec

# Both
bundle exec rake
```

## What you don't need anymore

The recurring user-land shim that reopens `Micro::Case::Result` to add
`Success` / `Failure` factories — usually parked at
`spec/support/micro_case_result.rb` or `test/support/micro_case_result.rb`
— is no longer needed once `require 'micro/case/with_test_doubles'` is in
your helper. The shape stays the same; only the source moves into the gem.
