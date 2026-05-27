# frozen_string_literal: true

require 'spec_helper'

# Return-value stubbing with `Micro::Case::Success.new` /
# `Micro::Case::Failure.new` — the test fakes the collaborator's return value
# and the SUT consumes it as if it had come from a real `FetchEmail` call.

RSpec.describe Affiliates::SendInvite do
  describe 'when the collaborator returns a success result' do
    let(:fetch_email_service) do
      class_double('Affiliates::FetchEmail').tap do |dbl|
        allow(dbl).to receive(:call)
          .with(id: 1)
          .and_return(Micro::Case::Success.new(data: { email: 'a@b.c' }))
      end
    end

    it 'sends the invite to the email returned by the collaborator' do
      result = described_class.call(id: 1, fetch_email_service: fetch_email_service)

      expect(result).to be_success
      expect(result.type).to eq(:ok)
      expect(result[:message]).to eq('Invite sent to a@b.c')
    end
  end

  describe 'when the collaborator returns a failure result' do
    let(:fetch_email_service) do
      class_double('Affiliates::FetchEmail').tap do |dbl|
        allow(dbl).to receive(:call)
          .with(id: 999)
          .and_return(Micro::Case::Failure.new(type: :not_found, data: { id: 999 }))
      end
    end

    it 'propagates a :no_email failure with the collaborator data' do
      result = described_class.call(id: 999, fetch_email_service: fetch_email_service)

      expect(result).to be_failure
      expect(result.type).to eq(:no_email)
      expect(result[:id]).to eq(999)
    end
  end

  describe 'the fabricated result' do
    it 'is a plain Micro::Case::Result, not a subclass' do
      result = Micro::Case::Success.new

      expect(result.class).to eq(Micro::Case::Result)
      expect(result).to be_success
      expect(result.type).to eq(:ok)
      expect(result.data).to eq({})
    end

    it 'carries a real Micro::Case as its use_case' do
      result = Micro::Case::Failure.new

      expect(result).to be_failure
      expect(result.type).to eq(:error)
      expect(result.use_case).to be_a(Micro::Case)
    end
  end
end
