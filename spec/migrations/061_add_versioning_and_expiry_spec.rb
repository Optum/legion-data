# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 061: add versioning and expiry columns to apollo_entries' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 61)
  end

  it 'migration file exists' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect(File.exist?(File.join(migration_path, '061_add_versioning_and_expiry.rb'))).to be true
  end

  context 'when postgres', if: Legion::Data::Connection.adapter == :postgres do
    let(:columns) { db.schema(:apollo_entries).to_h }

    describe 'parent_knowledge_id column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:parent_knowledge_id)
      end

      it 'is nullable' do
        expect(columns[:parent_knowledge_id][:allow_null]).to be true
      end

      it 'is a uuid type' do
        expect(columns[:parent_knowledge_id][:db_type]).to match(/uuid/i)
      end
    end

    describe 'is_latest column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:is_latest)
      end

      it 'is not nullable' do
        expect(columns[:is_latest][:allow_null]).to be false
      end

      it 'defaults to true' do
        expect(columns[:is_latest][:ruby_default]).to eq('true').or eq(true)
      end
    end

    describe 'supersession_type column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:supersession_type)
      end

      it 'is nullable' do
        expect(columns[:supersession_type][:allow_null]).to be true
      end

      it 'is a varchar (string type)' do
        expect(columns[:supersession_type][:db_type]).to match(/varchar|character varying/i)
      end
    end

    describe 'expires_at column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:expires_at)
      end

      it 'is nullable' do
        expect(columns[:expires_at][:allow_null]).to be true
      end
    end

    describe 'forget_reason column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:forget_reason)
      end

      it 'is nullable' do
        expect(columns[:forget_reason][:allow_null]).to be true
      end

      it 'is a varchar (string type)' do
        expect(columns[:forget_reason][:db_type]).to match(/varchar|character varying/i)
      end
    end

    describe 'is_inference column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:is_inference)
      end

      it 'is not nullable' do
        expect(columns[:is_inference][:allow_null]).to be false
      end

      it 'defaults to false' do
        expect(columns[:is_inference][:ruby_default]).to eq('false').or eq(false)
      end
    end

    describe 'indexes' do
      it 'has named index on parent_knowledge_id' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_parent_knowledge)
      end

      it 'parent_knowledge index covers the parent_knowledge_id column' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_parent_knowledge]
        expect(idx[:columns]).to include(:parent_knowledge_id)
      end

      it 'has named version chain index' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_version_chain)
      end

      it 'version chain index covers parent_knowledge_id and is_latest' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_version_chain]
        expect(idx[:columns]).to include(:parent_knowledge_id)
        expect(idx[:columns]).to include(:is_latest)
      end

      it 'has named expiry index' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_expiry)
      end

      it 'expiry index covers expires_at column' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_expiry]
        expect(idx[:columns]).to include(:expires_at)
      end

      it 'has named inference index' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_inference)
      end

      it 'inference index covers is_inference column' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_inference]
        expect(idx[:columns]).to include(:is_inference)
      end
    end

    it 'is idempotent when run twice' do
      migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
      expect do
        Sequel::Migrator.run(db, migration_path, target: 60)
        Sequel::Migrator.run(db, migration_path, target: 61)
      end.not_to raise_error
    end
  end

  context 'when not postgres', unless: Legion::Data::Connection.adapter == :postgres do
    it 'apollo_entries table does not exist (postgres-only feature)' do
      expect(db.table_exists?(:apollo_entries)).to be false
    end
  end
end
