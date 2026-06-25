# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/vector'

RSpec.describe Legion::Data::Vector do
  describe '.available?' do
    it 'returns false when no connection' do
      allow(Legion::Data).to receive(:connection).and_return(nil)
      expect(described_class.available?).to be false
    end

    it 'returns false for non-postgres adapter' do
      conn = double(adapter_scheme: :sqlite)
      allow(Legion::Data).to receive(:connection).and_return(conn)
      expect(described_class.available?).to be false
    end
  end

  describe '.ensure_extension!' do
    it 'returns false for non-postgres' do
      conn = double(adapter_scheme: :sqlite)
      allow(Legion::Data).to receive(:connection).and_return(conn)
      expect(described_class.ensure_extension!).to be false
    end

    it 'returns false when no connection' do
      allow(Legion::Data).to receive(:connection).and_return(nil)
      expect(described_class.ensure_extension!).to be false
    end
  end

  describe '.cosine_search' do
    it 'returns empty when pgvector not available' do
      allow(described_class).to receive(:available?).and_return(false)
      result = described_class.cosine_search(table: :memory_traces, column: :embedding, query_vector: [0.1, 0.2])
      expect(result).to eq([])
    end
  end

  describe '.l2_search' do
    it 'returns empty when pgvector not available' do
      allow(described_class).to receive(:available?).and_return(false)
      result = described_class.l2_search(table: :memory_traces, column: :embedding, query_vector: [0.1, 0.2])
      expect(result).to eq([])
    end
  end
end
