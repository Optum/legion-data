# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Migration 019: add audit hash chain columns' do
  let(:db) { Legion::Data::Connection.sequel }
  let(:migration_path) { File.expand_path('../../lib/legion/data/migrations', __dir__) }

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
      expect do
        Sequel::Migrator.run(db, migration_path)
      end.not_to raise_error
    end
  end

  describe 'rollback' do
    # Use an isolated SQLite database so the rollback does not corrupt the shared
    # test database state (rolling back 40+ migrations in SQLite leaves stale
    # schema caches that cause "duplicate column" errors on the way back up).
    let(:rollback_db_path) { File.join(Dir.tmpdir, "legion_test_rollback_#{::Process.pid}.db") } # rubocop:disable Style/RedundantConstantBase
    let(:rollback_db) do
      db = Sequel.connect("sqlite://#{rollback_db_path}")
      Sequel::Migrator.run(db, migration_path, target: 19)
      db
    end

    after do
      begin
        rollback_db.disconnect
      rescue StandardError
        nil
      end
      FileUtils.rm_f(rollback_db_path)
      FileUtils.rm_f("#{rollback_db_path}-journal")
    end

    it 'removes previous_hash on down' do
      Sequel::Migrator.run(rollback_db, migration_path, target: 18)
      expect(rollback_db.schema(:audit_log).map(&:first)).not_to include(:previous_hash)
    end

    it 'removes retention_tier on down' do
      Sequel::Migrator.run(rollback_db, migration_path, target: 18)
      expect(rollback_db.schema(:audit_log).map(&:first)).not_to include(:retention_tier)
    end
  end
end
