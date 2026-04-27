# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 074: widen Apollo entry identifiers' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 74)
  end

  it 'migration file exists' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect(File.exist?(File.join(migration_path, '074_widen_apollo_entry_identifiers.rb'))).to be true
  end

  context 'when postgres', if: Legion::Data::Connection.adapter == :postgres do
    let(:columns) { db.schema(:apollo_entries).to_h }

    it 'widens content_hash to 64 fixed characters' do
      expect(columns[:content_hash][:db_type]).to match(/char/i)
      expect(columns[:content_hash][:max_length]).to eq(64)
    end

    it 'widens knowledge_domain to 255 characters' do
      expect(columns[:knowledge_domain][:max_length]).to eq(255)
    end

    it 'widens source_provider to 255 characters' do
      expect(columns[:source_provider][:max_length]).to eq(255)
    end

    it 'widens source_agent to 255 characters' do
      expect(columns[:source_agent][:max_length]).to eq(255)
    end
  end

  context 'when not postgres', unless: Legion::Data::Connection.adapter == :postgres do
    it 'skips postgres-only apollo_entries changes' do
      expect(db.table_exists?(:apollo_entries)).to be false
    end
  end
end
