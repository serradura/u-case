# frozen_string_literal: true

require 'spec_helper'

# Block-form stubbing with `Micro::Case::Result::Success.to_yield` /
# `Result::Failure.to_yield` — the SUT consumes its collaborator via
# `service.call(...) { |on| on.success { ... }; on.failure { ... } }`,
# so the test needs a `Micro::Case::Result::Wrapper` to hand to RSpec's
# `and_yield`.

RSpec.describe Affiliates::DeliverReferral do
  let(:fetch_email_service) { class_double('Affiliates::FetchEmail') }

  describe 'when the collaborator yields a success wrapper' do
    before do
      allow(fetch_email_service).to receive(:call)
        .with(id: 1)
        .and_yield(Micro::Case::Result::Success.to_yield(data: { email: 'a@b.c' }))
    end

    it 'delivers the referral to the yielded email' do
      result = described_class.call(id: 1, fetch_email_service: fetch_email_service)

      expect(result).to be_success
      expect(result.type).to eq(:ok)
      expect(result[:delivered_to]).to eq('a@b.c')
    end
  end

  describe 'when the collaborator yields a failure wrapper' do
    before do
      allow(fetch_email_service).to receive(:call)
        .with(id: 999)
        .and_yield(Micro::Case::Result::Failure.to_yield(type: :not_found, data: { id: 999 }))
    end

    it 'maps the failure to :undeliverable with the original id' do
      result = described_class.call(id: 999, fetch_email_service: fetch_email_service)

      expect(result).to be_failure
      expect(result.type).to eq(:undeliverable)
      expect(result[:id]).to eq(999)
    end
  end

  describe 'the wrapper handed to and_yield' do
    it 'starts in the initial state (undefined output)' do
      wrapper = Micro::Case::Result::Success.to_yield(data: { x: 1 })

      expect(wrapper).to be_a(Micro::Case::Result::Wrapper)
      expect(wrapper.output).to eq(Kind::Undefined)
    end

    it 'can be driven by .success / .failure like the wrapper inside Micro::Case.call' do
      wrapper = Micro::Case::Result::Failure.to_yield(type: :err, data: { reason: 'bad' })

      wrapper.failure(:err) { |result| result[:reason] }

      expect(wrapper.output).to eq('bad')
    end
  end
end
