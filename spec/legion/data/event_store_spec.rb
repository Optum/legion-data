# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/event_store'

RSpec.describe Legion::Data::EventStore do
  describe 'GOVERNANCE_EVENT_TYPES' do
    it 'includes consent and extinction events' do
      expect(described_class::GOVERNANCE_EVENT_TYPES).to include('consent.granted', 'extinction.triggered')
    end
  end

  describe '.append' do
    it 'returns error when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      result = described_class.append(stream: 'test', type: 'consent.granted')
      expect(result[:error]).to include('db unavailable')
    end
  end

  describe '.read_stream' do
    it 'returns empty array when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      expect(described_class.read_stream('test')).to eq([])
    end
  end

  describe '.verify_chain' do
    it 'returns invalid when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      result = described_class.verify_chain('test')
      expect(result[:valid]).to be false
    end
  end
end
