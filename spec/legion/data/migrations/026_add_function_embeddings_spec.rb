# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 026: add function embeddings' do
  let(:db) { Legion::Data::Connection.sequel }

  describe 'schema changes' do
    it 'adds a description column to the functions table' do
      expect(db.schema(:functions).map(&:first)).to include(:description)
    end

    it 'adds an embedding column to the functions table' do
      expect(db.schema(:functions).map(&:first)).to include(:embedding)
    end

    it 'description column allows null' do
      col = db.schema(:functions).find { |c| c.first == :description }
      expect(col).not_to be_nil
      expect(col.last[:allow_null]).to be true
    end

    it 'embedding column allows null' do
      col = db.schema(:functions).find { |c| c.first == :embedding }
      expect(col).not_to be_nil
      expect(col.last[:allow_null]).to be true
    end
  end

  describe Legion::Data::Model::Function do
    before(:all) do
      Legion::Data::Connection.setup
      Legion::Data::Models.load
    end

    describe '#embedding_vector' do
      subject(:func) { described_class.new }

      it 'returns nil when embedding is nil' do
        func.embedding = nil
        expect(func.embedding_vector).to be_nil
      end

      it 'parses a JSON array embedding' do
        vec = [0.1, 0.2, 0.3]
        func.embedding = vec.to_json
        expect(func.embedding_vector).to eq(vec)
      end

      it 'returns nil for invalid JSON' do
        func.embedding = 'not-valid-json{'
        expect(func.embedding_vector).to be_nil
      end
    end

    describe '#embedding_vector=' do
      subject(:func) { described_class.new }

      it 'serializes a vector array to JSON' do
        vec = [0.1, 0.2, 0.3]
        func.embedding_vector = vec
        expect(func.embedding).to eq(vec.to_json)
      end

      it 'sets embedding to nil when assigned nil' do
        func.embedding_vector = nil
        expect(func.embedding).to be_nil
      end

      it 'round-trips through embedding_vector' do
        vec = Array.new(5) { |i| i * 0.1 }
        func.embedding_vector = vec
        expect(func.embedding_vector).to eq(vec)
      end
    end
  end
end
