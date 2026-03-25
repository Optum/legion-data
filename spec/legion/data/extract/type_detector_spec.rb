# frozen_string_literal: true

require 'legion/data/extract/type_detector'

RSpec.describe Legion::Data::Extract::TypeDetector do
  describe '.detect_from_path' do
    it 'detects PDF' do
      expect(described_class.detect_from_path('/tmp/doc.pdf')).to eq(:pdf)
    end

    it 'detects Markdown' do
      expect(described_class.detect_from_path('/tmp/readme.md')).to eq(:markdown)
    end

    it 'detects HTML variants' do
      expect(described_class.detect_from_path('/tmp/page.htm')).to eq(:html)
      expect(described_class.detect_from_path('/tmp/page.html')).to eq(:html)
    end

    it 'returns nil for unknown extensions' do
      expect(described_class.detect_from_path('/tmp/file.xyz')).to be_nil
    end

    it 'is case insensitive' do
      expect(described_class.detect_from_path('/tmp/FILE.PDF')).to eq(:pdf)
    end
  end
end
