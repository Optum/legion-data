# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 102: apollo_entries access_scope and identity indexes' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 102)
  end

  def index_names
    if db.adapter_scheme == :postgres
      db.indexes(:apollo_entries).keys.map(&:to_s)
    else
      db[:sqlite_master].where(type: 'index', tbl_name: 'apollo_entries').select_map(:name)
    end
  end

  context 'index creation' do
    it 'creates full index on access_scope' do
      expect(index_names).to include('idx_apollo_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names).to include('idx_apollo_identity_principal_id')
    end

    it 'creates partial index on identity_id' do
      expect(index_names).to include('idx_apollo_identity_id')
    end
  end
end
