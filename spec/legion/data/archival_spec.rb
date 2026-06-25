# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/archival'

RSpec.describe Legion::Data::Archival do
  describe 'ARCHIVE_TABLE_MAP' do
    it 'maps source tables to archive tables' do
      expect(described_class::ARCHIVE_TABLE_MAP[:tasks]).to eq(:tasks_archive)
      expect(described_class::ARCHIVE_TABLE_MAP[:metering_records]).to eq(:metering_records_archive)
    end
  end

  describe '.archive!' do
    it 'returns empty hash when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      result = described_class.archive!
      expect(result).to be_empty
    end
  end

  describe '.search' do
    it 'returns empty array when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      result = described_class.search(table: :tasks)
      expect(result).to eq([])
    end
  end

  describe '.restore' do
    it 'returns 0 when db unavailable' do
      allow(described_class).to receive(:db_ready?).and_return(false)
      expect(described_class.restore(table: :tasks, ids: [1])).to eq(0)
    end
  end
end
