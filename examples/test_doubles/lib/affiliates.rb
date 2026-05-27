# frozen_string_literal: true

require 'u-case'

# The "Affiliates" domain has three small use cases:
#
#   * Affiliates::FetchEmail        — collaborator. Looks up an affiliate's
#                                     email by id. The real implementation
#                                     would hit a database or HTTP API; in
#                                     tests, callers fake its result.
#
#   * Affiliates::SendInvite        — consumer. Uses FetchEmail via its
#                                     *return value* (the most common form
#                                     for use-case-calls-use-case code).
#
#   * Affiliates::DeliverReferral   — consumer. Uses FetchEmail via the
#                                     *block form*  — `service.call(...) { |on| ... }`
#                                     so it can branch on success/failure
#                                     types without an intermediate variable.
#
# Both consumers receive the collaborator through an attribute, which makes
# them trivially fakeable in tests via RSpec stubs or Mocha expectations.
# That's the seam that `Micro::Case::Success.new` /
# `Micro::Case::Failure.new` / `.to_yield` are built for.

module Affiliates
  class FetchEmail < Micro::Case
    attribute :id

    DIRECTORY = {
      1 => 'rodrigo@example.com',
      2 => 'alice@example.com'
    }.freeze

    def call!
      email = DIRECTORY[id]

      return Failure(:not_found, result: { id: id }) if email.nil?

      Success result: { email: email }
    end
  end

  class SendInvite < Micro::Case
    attribute :id
    attribute :fetch_email_service, default: FetchEmail

    def call!
      result = fetch_email_service.call(id: id)

      return Failure(:no_email, result: result.data) if result.failure?

      Success result: { message: "Invite sent to #{result[:email]}" }
    end
  end

  class DeliverReferral < Micro::Case
    attribute :id
    attribute :fetch_email_service, default: FetchEmail

    def call!
      fetch_email_service.call(id: id) do |on|
        on.success { |result, _| return Success result: { delivered_to: result[:email] } }
        on.failure { |result, _| return Failure(:undeliverable, result: { id: result[:id] }) }
      end
    end
  end
end
