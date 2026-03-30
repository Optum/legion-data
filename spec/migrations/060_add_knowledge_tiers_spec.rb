# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 060: add knowledge tier columns to apollo_entries' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 60)
  end

  it 'migration file exists' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect(File.exist?(File.join(migration_path, '060_add_knowledge_tiers.rb'))).to be true
  end

  context 'when postgres', if: Legion::Data::Connection.adapter == :postgres do
    let(:columns) { db.schema(:apollo_entries).to_h }

    describe 'summary_l0 column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:summary_l0)
      end

      it 'is nullable' do
        expect(columns[:summary_l0][:allow_null]).to be true
      end

      it 'is a varchar (string type)' do
        expect(columns[:summary_l0][:db_type]).to match(/varchar|character varying/i)
      end
    end

    describe 'summary_l1 column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:summary_l1)
      end

      it 'is nullable' do
        expect(columns[:summary_l1][:allow_null]).to be true
      end

      it 'is a text type' do
        expect(columns[:summary_l1][:db_type]).to match(/text/i)
      end
    end

    describe 'knowledge_tier column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:knowledge_tier)
      end

      it 'is not nullable' do
        expect(columns[:knowledge_tier][:allow_null]).to be false
      end

      it 'defaults to L2' do
        expect(columns[:knowledge_tier][:ruby_default]).to eq('L2')
      end
    end

    describe 'parent_entry_id column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:parent_entry_id)
      end

      it 'is nullable' do
        expect(columns[:parent_entry_id][:allow_null]).to be true
      end

      it 'is a uuid type' do
        expect(columns[:parent_entry_id][:db_type]).to match(/uuid/i)
      end
    end

    describe 'l0_generated_at column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:l0_generated_at)
      end

      it 'is nullable' do
        expect(columns[:l0_generated_at][:allow_null]).to be true
      end
    end

    describe 'l1_generated_at column' do
      it 'exists on apollo_entries' do
        expect(columns.keys).to include(:l1_generated_at)
      end

      it 'is nullable' do
        expect(columns[:l1_generated_at][:allow_null]).to be true
      end
    end

    describe 'indexes' do
      it 'has named index on knowledge_tier' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_knowledge_tier)
      end

      it 'knowledge_tier index covers the knowledge_tier column' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_knowledge_tier]
        expect(idx[:columns]).to include(:knowledge_tier)
      end

      it 'has named index on parent_entry_id' do
        expect(db.indexes(:apollo_entries)).to have_key(:idx_apollo_parent_entry)
      end

      it 'parent_entry index covers the parent_entry_id column' do
        idx = db.indexes(:apollo_entries)[:idx_apollo_parent_entry]
        expect(idx[:columns]).to include(:parent_entry_id)
      end
    end

    it 'is idempotent when run twice' do
      migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
      expect do
        Sequel::Migrator.run(db, migration_path, target: 60)
      end.not_to raise_error
    end
  end

  context 'when not postgres', unless: Legion::Data::Connection.adapter == :postgres do
    it 'apollo_entries table does not exist (postgres-only feature)' do
      expect(db.table_exists?(:apollo_entries)).to be false
    end
  end
end
