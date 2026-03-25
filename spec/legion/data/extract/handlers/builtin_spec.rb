# frozen_string_literal: true

require 'legion/data/extract'
require 'legion/data/extract/handlers/text'
require 'legion/data/extract/handlers/markdown'
require 'legion/data/extract/handlers/csv'
require 'legion/data/extract/handlers/json'
require 'legion/data/extract/handlers/jsonl'
require 'tempfile'

RSpec.describe 'Built-in Extract Handlers' do
  describe Legion::Data::Extract::Handlers::Text do
    it 'extracts text from a file' do
      f = Tempfile.new(['test', '.txt'])
      f.write('hello world')
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to eq('hello world')
      expect(result[:metadata][:bytes]).to eq(11)
    ensure
      f&.close!
    end

    it 'extracts from IO' do
      io = StringIO.new('from io')
      result = described_class.extract(io)
      expect(result[:text]).to eq('from io')
    end
  end

  describe Legion::Data::Extract::Handlers::Markdown do
    it 'strips YAML frontmatter' do
      f = Tempfile.new(['test', '.md'])
      f.write("---\ntitle: Test\n---\n# Hello\nWorld")
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to eq("# Hello\nWorld")
      expect(result[:metadata][:has_frontmatter]).to be true
    ensure
      f&.close!
    end

    it 'passes through markdown without frontmatter' do
      f = Tempfile.new(['test', '.md'])
      f.write('# Just Markdown')
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to eq('# Just Markdown')
    ensure
      f&.close!
    end
  end

  describe Legion::Data::Extract::Handlers::Csv do
    it 'extracts CSV as key-value text' do
      f = Tempfile.new(['test', '.csv'])
      f.write("name,age\nAlice,30\nBob,25")
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to include('name: Alice')
      expect(result[:metadata][:rows]).to eq(2)
      expect(result[:metadata][:columns]).to eq(2)
    ensure
      f&.close!
    end
  end

  describe Legion::Data::Extract::Handlers::Json do
    it 'pretty-prints JSON' do
      f = Tempfile.new(['test', '.json'])
      f.write('{"key":"value"}')
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to include('"key"')
      expect(result[:metadata][:keys]).to eq(['key'])
    ensure
      f&.close!
    end
  end

  describe Legion::Data::Extract::Handlers::Jsonl do
    it 'extracts JSONL lines' do
      f = Tempfile.new(['test', '.jsonl'])
      f.write("{\"a\":1}\n{\"b\":2}")
      f.flush
      result = described_class.extract(f.path)
      expect(result[:text]).to include('"a"')
      expect(result[:metadata][:lines]).to eq(2)
    ensure
      f&.close!
    end
  end
end
