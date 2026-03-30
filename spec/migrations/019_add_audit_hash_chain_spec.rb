# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 019: add audit hash chain columns' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 19)
  end

  describe 'audit_log table schema' do
    it 'has a previous_hash column' do
      expect(db.schema(:audit_log).map(&:first)).to include(:previous_hash)
    end

    it 'has a retention_tier column' do
      expect(db.schema(:audit_log).map(&:first)).to include(:retention_tier)
    end

    it 'retention_tier defaults to hot' do
      col = db.schema(:audit_log).find { |c| c.first == :retention_tier }
      expect(col).not_to be_nil
      # Prefer ruby_default (normalized by Sequel); fall back to stripping raw default for older adapters
      default_val = col.last[:ruby_default] || col.last[:default].to_s.gsub(/\A'|'\z/, '')
      expect(default_val.to_s).to eq('hot')
    end
  end

  describe 'audit_log indexes' do
    it 'has an index on record_hash' do
      expect(db.indexes(:audit_log)).to have_key(:audit_log_record_hash_index)
    end

    it 'has an index on retention_tier' do
      expect(db.indexes(:audit_log)).to have_key(:audit_log_retention_tier_index)
    end
  end

  describe 'idempotency' do
    it 'does not raise when run twice' do
      migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
      expect do
        Sequel::Migrator.run(db, migration_path, target: 19)
      end.not_to raise_error
    end
  end

  describe 'rollback' do
    before(:all) do
      migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
      Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 18)
    end

    it 'removes previous_hash on down' do
      expect(Legion::Data::Connection.sequel.schema(:audit_log).map(&:first)).not_to include(:previous_hash)
    end

    it 'removes retention_tier on down' do
      expect(Legion::Data::Connection.sequel.schema(:audit_log).map(&:first)).not_to include(:retention_tier)
    end

    after(:all) do
      migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
      Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 19)
    end
  end
end
