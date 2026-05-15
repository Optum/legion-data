# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 100: apollo_entries identity and access_scope columns' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 100)
  end

  context 'when postgres', if: Legion::Data::Connection.adapter == :postgres do
    it 'adds access_scope to apollo_entries with default global' do
      columns = db.schema(:apollo_entries).to_h
      expect(columns).to have_key(:access_scope)
      expect(columns[:access_scope][:default]).to eq('global')
      expect(columns[:access_scope][:allow_null]).to be false
    end

    it 'adds identity_principal_id as nullable integer to apollo_entries' do
      columns = db.schema(:apollo_entries).to_h
      expect(columns).to have_key(:identity_principal_id)
      expect(columns[:identity_principal_id][:allow_null]).to be true
    end

    it 'adds identity_id as nullable integer to apollo_entries' do
      columns = db.schema(:apollo_entries).to_h
      expect(columns).to have_key(:identity_id)
      expect(columns[:identity_id][:allow_null]).to be true
    end

    it 'adds identity_canonical_name as nullable varchar to apollo_entries' do
      columns = db.schema(:apollo_entries).to_h
      expect(columns).to have_key(:identity_canonical_name)
      expect(columns[:identity_canonical_name][:allow_null]).to be true
    end

    it 'adds access_scope to apollo_entries_archive' do
      columns = db.schema(:apollo_entries_archive).to_h
      expect(columns).to have_key(:access_scope)
    end

    it 'adds identity columns to apollo_entries_archive' do
      columns = db.schema(:apollo_entries_archive).to_h
      expect(columns).to have_key(:identity_principal_id)
      expect(columns).to have_key(:identity_id)
      expect(columns).to have_key(:identity_canonical_name)
    end

    it 'existing rows default to global access_scope' do
      db[:apollo_entries].insert(
        content: 'test', content_type: 'observation', source_agent: 'test', status: 'candidate'
      )
      row = db[:apollo_entries].first
      expect(row[:access_scope]).to eq('global')
    end
  end

  context 'when not postgres', unless: Legion::Data::Connection.adapter == :postgres do
    it 'skips the migration silently' do
      expect(db.table_exists?(:apollo_entries)).to be false
    end
  end
end
