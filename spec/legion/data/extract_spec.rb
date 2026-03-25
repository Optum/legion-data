# frozen_string_literal: true

require 'legion/data/extract'
require 'legion/data/extract/handlers/text'
require 'legion/data/extract/handlers/markdown'
require 'legion/data/extract/handlers/csv'
require 'legion/data/extract/handlers/json'
require 'legion/data/extract/handlers/jsonl'
require 'tempfile'

RSpec.describe Legion::Data::Extract do
  describe '.extract' do
    context 'with unknown type' do
      it 'returns error' do
        result = described_class.extract('test string', type: :auto)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:unknown_type)
      end
    end

    context 'with explicit unknown type' do
      it 'returns no_handler error' do
        result = described_class.extract('test', type: :foobar)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:no_handler)
      end
    end
  end

  describe '.supported_types' do
    it 'returns an array of symbols' do
      types = described_class.supported_types
      expect(types).to be_an(Array)
      types.each { |t| expect(t).to be_a(Symbol) }
    end
  end

  describe '.can_extract?' do
    it 'returns false for unregistered types' do
      expect(described_class.can_extract?(:foobar)).to be false
    end
  end

  describe '.register_handler' do
    it 'registers a custom handler' do
      custom = Class.new(Legion::Data::Extract::Handlers::Base) do
        def self.type = :custom_test
        def self.extract(source) = { text: source.to_s, metadata: {} }
      end
      described_class.register_handler(:custom_test, custom)
      expect(described_class.can_extract?(:custom_test)).to be true
    end
  end

  describe '.extract with builtin handlers' do
    it 'extracts a text file by path' do
      f = Tempfile.new(['test', '.txt'])
      f.write('integration test')
      f.flush
      result = described_class.extract(f.path)
      expect(result[:success]).to be true
      expect(result[:text]).to eq('integration test')
      expect(result[:type]).to eq(:text)
    ensure
      f&.close!
    end

    it 'extracts with explicit type override' do
      f = Tempfile.new(['test', '.unknown'])
      f.write('forced text')
      f.flush
      result = described_class.extract(f.path, type: :text)
      expect(result[:success]).to be true
      expect(result[:text]).to eq('forced text')
    ensure
      f&.close!
    end
  end
end
