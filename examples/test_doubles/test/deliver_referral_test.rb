# frozen_string_literal: true

require_relative 'test_helper'

# Block-form stubbing with `Micro::Case::Success.to_yield` /
# `Micro::Case::Failure.to_yield` — Mocha's `yields(...)` hands the wrapper to
# the SUT's block, which uses it to branch on `on.success` / `on.failure`.

class DeliverReferralTest < Minitest::Test
  def test_delivers_to_the_email_yielded_by_the_collaborator
    fetch_email_service = mock('Affiliates::FetchEmail')

    fetch_email_service
      .stubs(:call)
      .with(id: 1)
      .yields(Micro::Case::Success.to_yield(data: { email: 'a@b.c' }))

    result = Affiliates::DeliverReferral.call(id: 1, fetch_email_service: fetch_email_service)

    assert_predicate(result, :success?)
    assert_equal(:ok, result.type)
    assert_equal('a@b.c', result[:delivered_to])
  end

  def test_maps_a_failure_yield_to_undeliverable
    fetch_email_service = mock('Affiliates::FetchEmail')

    fetch_email_service
      .stubs(:call)
      .with(id: 999)
      .yields(Micro::Case::Failure.to_yield(type: :not_found, data: { id: 999 }))

    result = Affiliates::DeliverReferral.call(id: 999, fetch_email_service: fetch_email_service)

    assert_predicate(result, :failure?)
    assert_equal(:undeliverable, result.type)
    assert_equal(999, result[:id])
  end

  def test_to_yield_wrapper_starts_in_the_initial_state
    wrapper = Micro::Case::Success.to_yield(data: { x: 1 })

    assert_kind_of(Micro::Case::Result::Wrapper, wrapper)
    assert_same(Kind::Undefined, wrapper.output)
  end

  def test_to_yield_wrapper_can_be_driven_via_success_and_failure
    wrapper = Micro::Case::Failure.to_yield(type: :err, data: { reason: 'bad' })

    wrapper.failure(:err) { |result| result[:reason] }

    assert_equal('bad', wrapper.output)
  end
end
