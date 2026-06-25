# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/archival'
require 'legion/data/retention'

RSpec.describe Legion::Data::Archival do
  let(:db) { Legion::Data.connection }

  describe '.archive_completed_tasks' do
    let(:cutoff_time) { Time.now - (100 * 86_400) }

    before do
      # Clean up any leftover test rows
      db[:tasks].where(status: %w[completed failed running]).delete rescue nil # rubocop:disable Style/RescueModifier
    end

    after do
      db[:tasks].where(status: %w[completed failed running]).delete rescue nil # rubocop:disable Style/RescueModifier
      db[:tasks_archive].where(archive_reason: 'completed_task_archival').delete rescue nil # rubocop:disable Style/RescueModifier
    end

    it 'returns a hash with :archived and :cutoff keys' do
      result = described_class.archive_completed_tasks(days_old: 90)
      expect(result).to have_key(:archived)
      expect(result).to have_key(:cutoff)
    end

    it 'moves old completed/failed tasks to tasks_archive' do
      db[:tasks].insert(status: 'completed', created: cutoff_time - 1)
      db[:tasks].insert(status: 'failed', created: cutoff_time - 1)
      result = described_class.archive_completed_tasks(days_old: 90)
      expect(result[:archived]).to be >= 2
    end

    it 'leaves recent completed tasks in the tasks table' do
      id = db[:tasks].insert(status: 'completed', created: Time.now)
      described_class.archive_completed_tasks(days_old: 90)
      expect(db[:tasks].where(id: id).count).to eq(1)
    end

    it 'leaves non-completed/failed tasks in place regardless of age' do
      id = db[:tasks].insert(status: 'running', created: cutoff_time - 1)
      described_class.archive_completed_tasks(days_old: 90)
      expect(db[:tasks].where(id: id).count).to eq(1)
    end

    it 'returns archived: 0 when tasks table does not exist' do
      allow(db).to receive(:table_exists?).with(:tasks).and_return(false)
      allow(db).to receive(:table_exists?).with(:tasks_archive).and_return(true)
      result = described_class.archive_completed_tasks
      expect(result[:archived]).to eq(0)
    end

    it 'returns archived: 0 when tasks_archive table does not exist' do
      allow(db).to receive(:table_exists?).with(:tasks).and_return(true)
      allow(db).to receive(:table_exists?).with(:tasks_archive).and_return(false)
      result = described_class.archive_completed_tasks
      expect(result[:archived]).to eq(0)
    end

    it 'cutoff is an ISO8601 string' do
      result = described_class.archive_completed_tasks(days_old: 90)
      expect(result[:cutoff]).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end

  describe '.run_scheduled_archival' do
    it 'returns a hash with :tasks key' do
      result = described_class.run_scheduled_archival
      expect(result).to have_key(:tasks)
    end

    it 'delegates to archive_completed_tasks' do
      allow(described_class).to receive(:archive_completed_tasks).and_return({ archived: 5, cutoff: '2026-01-01' })
      result = described_class.run_scheduled_archival
      expect(result[:tasks][:archived]).to eq(5)
    end

    it 'includes metering key when metering_records table exists' do
      allow(described_class).to receive(:archive_completed_tasks).and_return({ archived: 0, cutoff: Time.now.iso8601 })
      allow(db).to receive(:table_exists?).with(:metering_records).and_return(true)
      allow(Legion::Data::Retention).to receive(:archive_old_records).and_return({ archived: 3, table: :metering_records })
      result = described_class.run_scheduled_archival
      expect(result).to have_key(:metering)
    end

    it 'omits metering key when metering_records table does not exist' do
      allow(described_class).to receive(:archive_completed_tasks).and_return({ archived: 0, cutoff: Time.now.iso8601 })
      allow(db).to receive(:table_exists?).with(:metering_records).and_return(false)
      result = described_class.run_scheduled_archival
      expect(result).not_to have_key(:metering)
    end
  end
end
