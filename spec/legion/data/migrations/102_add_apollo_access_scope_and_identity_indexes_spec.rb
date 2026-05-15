# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 102: apollo_entries access_scope and identity indexes' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 102)
  end

  context 'index creation' do
    it 'creates full index on access_scope' do
      indexes = db.indexes(:apollo_entries)
      expect(indexes).to have_key(:idx_apollo_access_scope)
      expect(indexes[:idx_apollo_access_scope][:columns]).to eq([:access_scope])
    end

    it 'creates partial index on identity_principal_id' do
      indexes = db.indexes(:apollo_entries)
      expect(indexes).to have_key(:idx_apollo_identity_principal_id)
      expect(indexes[:idx_apollo_identity_principal_id][:columns]).to eq([:identity_principal_id])
    end

    it 'creates partial index on identity_id' do
      indexes = db.indexes(:apollo_entries)
      expect(indexes).to have_key(:idx_apollo_identity_id)
      expect(indexes[:idx_apollo_identity_id][:columns]).to eq([:identity_id])
    end
  end
end
