# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/event_store'
require 'legion/data/event_store/projection'

RSpec.describe Legion::Data::EventStore::Projection do
  describe '#apply' do
    it 'raises NotImplementedError' do
      expect { described_class.new.apply({}) }.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe Legion::Data::EventStore::ConsentState do
  let(:projection) { described_class.new }

  it 'tracks granted consents' do
    projection.apply({ type: 'consent.granted', data: { scope: 'llm', tier: 'full' } })
    expect(projection.state['llm']).to eq('full')
  end

  it 'removes revoked consents' do
    projection.apply({ type: 'consent.granted', data: { scope: 'llm', tier: 'full' } })
    projection.apply({ type: 'consent.revoked', data: { scope: 'llm' } })
    expect(projection.state).not_to have_key('llm')
  end

  it 'updates modified consents' do
    projection.apply({ type: 'consent.granted', data: { scope: 'llm', tier: 'full' } })
    projection.apply({ type: 'consent.modified', data: { scope: 'llm', tier: 'limited' } })
    expect(projection.state['llm']).to eq('limited')
  end
end

RSpec.describe Legion::Data::EventStore::GovernanceTimeline do
  let(:projection) { described_class.new }

  it 'appends events to timeline' do
    projection.apply({ type: 'extinction.triggered', stream: 'sys', created_at: Time.now, data: {} })
    expect(projection.state.size).to eq(1)
  end
end
