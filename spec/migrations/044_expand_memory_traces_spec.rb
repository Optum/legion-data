# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 044: expand memory_traces schema' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 46)
  end

  let(:columns) { db.schema(:memory_traces).map(&:first) }

  it 'memory_traces table exists' do
    expect(db.table_exists?(:memory_traces)).to be true
  end

  %i[
    trace_id strength peak_strength base_decay_rate
    emotional_valence emotional_intensity domain_tags origin
    source_agent_id storage_tier last_reinforced last_decayed
    reinforcement_count unresolved consolidation_candidate
    parent_trace_id encryption_key_id partition_id
  ].each do |col|
    it "has column #{col}" do
      expect(columns).to include(col)
    end
  end

  it 'storage_tier defaults to warm' do
    col = db.schema(:memory_traces).find { |c| c.first == :storage_tier }
    expect(col).not_to be_nil
    expect(col.last[:ruby_default]).to eq('warm')
  end

  it 'has an index on storage_tier' do
    expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_storage_tier)
  end

  it 'has an index on partition_id' do
    expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_partition_id)
  end

  it 'has a composite index on partition_id and trace_type' do
    expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_partition_type)
  end

  it 'has an index on unresolved' do
    expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_unresolved)
  end
end
