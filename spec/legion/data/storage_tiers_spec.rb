# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/storage_tiers'

RSpec.describe Legion::Data::StorageTiers do
  describe '.archive_to_warm' do
    it 'returns zero when no connection' do
      allow(Legion::Data).to receive(:connection).and_return(nil)
      result = described_class.archive_to_warm(table: :tasks)
      expect(result[:archived]).to eq(0)
      expect(result[:reason]).to eq('no_connection')
    end

    it 'returns zero when no archive table' do
      conn = Legion::Data.connection
      allow(conn).to receive(:table_exists?).with(:data_archive).and_return(false)
      result = described_class.archive_to_warm(table: :tasks)
      expect(result[:archived]).to eq(0)
      expect(result[:reason]).to eq('no_archive_table')
    end
  end

  describe '.export_to_cold' do
    it 'returns zero when no archive table' do
      conn = Legion::Data.connection
      allow(conn).to receive(:table_exists?).with(:data_archive).and_return(false)
      result = described_class.export_to_cold
      expect(result[:exported]).to eq(0)
    end
  end

  describe 'TIERS' do
    it 'defines three tiers' do
      expect(described_class::TIERS.keys).to contain_exactly(:hot, :warm, :cold)
    end

    it 'assigns ascending numeric values' do
      expect(described_class::TIERS[:hot]).to eq(0)
      expect(described_class::TIERS[:warm]).to eq(1)
      expect(described_class::TIERS[:cold]).to eq(2)
    end
  end
end
