# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/retention'

RSpec.describe Legion::Data::Retention do
  let(:db) { Legion::Data.connection }
  let(:table) { :retention_test_records }
  let(:archive_table) { :retention_test_records_archive }

  before(:each) do
    db.drop_table?(table)
    db.drop_table?(archive_table)

    db.create_table(table) do
      primary_key :id
      String :name
      DateTime :created_at
    end
  end

  after(:each) do
    db.drop_table?(archive_table)
    db.drop_table?(table)
  end

  def insert_record(name:, created_at:)
    db[table].insert(name: name, created_at: created_at)
  end

  describe '.archive_table_name' do
    it 'appends _archive suffix as symbol' do
      expect(described_class.archive_table_name(:tasks)).to eq(:tasks_archive)
    end

    it 'works with string input' do
      expect(described_class.archive_table_name('events')).to eq(:events_archive)
    end
  end

  describe '.archive_old_records' do
    it 'moves records older than archive_after_days to archive table' do
      insert_record(name: 'old', created_at: Time.now - (100 * 86_400))
      insert_record(name: 'recent', created_at: Time.now - (10 * 86_400))

      described_class.archive_old_records(table: table, archive_after_days: 90)

      expect(db[table].count).to eq(1)
      expect(db[table].first[:name]).to eq('recent')
      expect(db[archive_table].count).to eq(1)
      expect(db[archive_table].first[:name]).to eq('old')
    end

    it 'returns the correct archived count' do
      insert_record(name: 'old1', created_at: Time.now - (200 * 86_400))
      insert_record(name: 'old2', created_at: Time.now - (150 * 86_400))
      insert_record(name: 'new', created_at: Time.now)

      result = described_class.archive_old_records(table: table, archive_after_days: 90)

      expect(result[:archived]).to eq(2)
      expect(result[:table]).to eq(table)
    end

    it 'returns zero archived when no records are old enough' do
      insert_record(name: 'fresh', created_at: Time.now - (5 * 86_400))

      result = described_class.archive_old_records(table: table, archive_after_days: 90)

      expect(result[:archived]).to eq(0)
    end

    it 'returns zero when no connection' do
      allow(Legion::Data).to receive(:connection).and_return(nil)
      result = described_class.archive_old_records(table: table)
      expect(result[:archived]).to eq(0)
    end

    it 'handles an empty table gracefully' do
      result = described_class.archive_old_records(table: table, archive_after_days: 90)
      expect(result[:archived]).to eq(0)
    end

    it 'creates the archive table automatically if it does not exist' do
      insert_record(name: 'old', created_at: Time.now - (100 * 86_400))

      expect(db.table_exists?(archive_table)).to be false
      described_class.archive_old_records(table: table, archive_after_days: 90)
      expect(db.table_exists?(archive_table)).to be true
    end

    it 'works with a custom date_column' do
      db.drop_table?(table)
      db.create_table(table) do
        primary_key :id
        String :name
        DateTime :recorded_at
      end

      db[table].insert(name: 'old', recorded_at: Time.now - (100 * 86_400))
      db[table].insert(name: 'new', recorded_at: Time.now)

      result = described_class.archive_old_records(
        table:              table,
        date_column:        :recorded_at,
        archive_after_days: 90
      )

      expect(result[:archived]).to eq(1)
      expect(db[archive_table].first[:name]).to eq('old')
    end
  end

  describe '.purge_expired_records' do
    before(:each) do
      db.create_table(archive_table) do
        primary_key :id
        String :name
        DateTime :created_at
        DateTime :archived_at
      end
    end

    it 'deletes records from archive older than retention_years' do
      db[archive_table].insert(name: 'ancient', created_at: Time.now - (8 * 365 * 86_400))
      db[archive_table].insert(name: 'recent_archive', created_at: Time.now - (2 * 365 * 86_400))

      result = described_class.purge_expired_records(table: table, retention_years: 7)

      expect(result[:purged]).to eq(1)
      expect(db[archive_table].count).to eq(1)
      expect(db[archive_table].first[:name]).to eq('recent_archive')
    end

    it 'returns the correct purged count' do
      db[archive_table].insert(name: 'old1', created_at: Time.now - (10 * 365 * 86_400))
      db[archive_table].insert(name: 'old2', created_at: Time.now - (9 * 365 * 86_400))

      result = described_class.purge_expired_records(table: table, retention_years: 7)

      expect(result[:purged]).to eq(2)
      expect(result[:table]).to eq(table)
    end

    it 'returns zero when archive table does not exist' do
      db.drop_table?(archive_table)
      result = described_class.purge_expired_records(table: table, retention_years: 7)
      expect(result[:purged]).to eq(0)
    end

    it 'handles an empty archive table gracefully' do
      result = described_class.purge_expired_records(table: table, retention_years: 7)
      expect(result[:purged]).to eq(0)
    end

    it 'works with a custom date_column' do
      db.drop_table?(archive_table)
      db.create_table(archive_table) do
        primary_key :id
        String :name
        DateTime :recorded_at
        DateTime :archived_at
      end

      db[archive_table].insert(name: 'ancient', recorded_at: Time.now - (8 * 365 * 86_400))
      db[archive_table].insert(name: 'recent', recorded_at: Time.now - (1 * 365 * 86_400))

      result = described_class.purge_expired_records(
        table:           table,
        date_column:     :recorded_at,
        retention_years: 7
      )

      expect(result[:purged]).to eq(1)
      expect(db[archive_table].first[:name]).to eq('recent')
    end
  end

  describe '.retention_status' do
    it 'reports correct active and archived counts' do
      db.create_table(archive_table) do
        primary_key :id
        String :name
        DateTime :created_at
        DateTime :archived_at
      end

      insert_record(name: 'active1', created_at: Time.now)
      insert_record(name: 'active2', created_at: Time.now)
      db[archive_table].insert(name: 'arch1', created_at: Time.now - (200 * 86_400))

      status = described_class.retention_status(table: table)

      expect(status[:table]).to eq(table)
      expect(status[:active_count]).to eq(2)
      expect(status[:archived_count]).to eq(1)
    end

    it 'reports oldest_active timestamp' do
      older = Time.now - (60 * 86_400)
      insert_record(name: 'older', created_at: older)
      insert_record(name: 'newer', created_at: Time.now)

      status = described_class.retention_status(table: table)

      expect(status[:oldest_active]).not_to be_nil
    end

    it 'reports oldest_archived timestamp when archive exists' do
      db.create_table(archive_table) do
        primary_key :id
        String :name
        DateTime :created_at
        DateTime :archived_at
      end

      db[archive_table].insert(name: 'old', created_at: Time.now - (500 * 86_400))

      status = described_class.retention_status(table: table)

      expect(status[:oldest_archived]).not_to be_nil
    end

    it 'returns nil for oldest_active when table is empty' do
      status = described_class.retention_status(table: table)
      expect(status[:oldest_active]).to be_nil
    end

    it 'returns nil for oldest_archived when archive table does not exist' do
      status = described_class.retention_status(table: table)
      expect(status[:archived_count]).to eq(0)
      expect(status[:oldest_archived]).to be_nil
    end
  end

  describe 'constants' do
    it 'defines DEFAULT_RETENTION_YEARS as 7' do
      expect(described_class::DEFAULT_RETENTION_YEARS).to eq(7)
    end

    it 'defines DEFAULT_ARCHIVE_AFTER_DAYS as 90' do
      expect(described_class::DEFAULT_ARCHIVE_AFTER_DAYS).to eq(90)
    end
  end
end
