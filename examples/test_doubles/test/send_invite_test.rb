# frozen_string_literal: true

require_relative 'test_helper'

# Return-value stubbing with `Micro::Case::Result::Success.new` /
# `Result::Failure.new` — the test fakes the collaborator's return value
# using Mocha's `stubs(...).returns(...)`.

class SendInviteTest < Minitest::Test
  def test_sends_the_invite_when_the_collaborator_returns_success
    fetch_email_service = mock('Affiliates::FetchEmail')

    fetch_email_service
      .stubs(:call)
      .with(id: 1)
      .returns(Micro::Case::Result::Success.new(data: { email: 'a@b.c' }))

    result = Affiliates::SendInvite.call(id: 1, fetch_email_service: fetch_email_service)

    assert_predicate(result, :success?)
    assert_equal(:ok, result.type)
    assert_equal('Invite sent to a@b.c', result[:message])
  end

  def test_propagates_a_no_email_failure_when_the_collaborator_returns_failure
    fetch_email_service = mock('Affiliates::FetchEmail')

    fetch_email_service
      .stubs(:call)
      .with(id: 999)
      .returns(Micro::Case::Result::Failure.new(type: :not_found, data: { id: 999 }))

    result = Affiliates::SendInvite.call(id: 999, fetch_email_service: fetch_email_service)

    assert_predicate(result, :failure?)
    assert_equal(:no_email, result.type)
    assert_equal(999, result[:id])
  end

  def test_fabricated_success_result_is_a_plain_micro_case_result
    result = Micro::Case::Result::Success.new

    assert_equal(Micro::Case::Result, result.class)
    assert_predicate(result, :success?)
    assert_equal(:ok, result.type)
    assert_equal({}, result.data)
  end

  def test_fabricated_failure_result_carries_a_real_micro_case_as_use_case
    result = Micro::Case::Result::Failure.new

    assert_predicate(result, :failure?)
    assert_equal(:error, result.type)
    assert_kind_of(Micro::Case, result.use_case)
  end
end
