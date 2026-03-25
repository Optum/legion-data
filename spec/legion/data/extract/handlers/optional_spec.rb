# frozen_string_literal: true

require 'legion/data/extract'
require 'legion/data/extract/handlers/pdf'
require 'legion/data/extract/handlers/docx'
require 'legion/data/extract/handlers/pptx'
require 'legion/data/extract/handlers/xlsx'
require 'legion/data/extract/handlers/html'
require 'tempfile'

RSpec.describe 'Optional Extract Handlers' do
  describe Legion::Data::Extract::Handlers::Pdf do
    it 'is registered for :pdf type' do
      expect(Legion::Data::Extract::Handlers::Base.for_type(:pdf)).to eq(described_class)
    end

    it 'declares pdf-reader gem dependency' do
      expect(described_class.gem_name).to eq('pdf-reader')
    end
  end

  describe Legion::Data::Extract::Handlers::Docx do
    it 'is registered for :docx type' do
      expect(Legion::Data::Extract::Handlers::Base.for_type(:docx)).to eq(described_class)
    end

    it 'declares docx gem dependency' do
      expect(described_class.gem_name).to eq('docx')
    end
  end

  describe Legion::Data::Extract::Handlers::Pptx do
    it 'is registered for :pptx type' do
      expect(Legion::Data::Extract::Handlers::Base.for_type(:pptx)).to eq(described_class)
    end

    it 'declares rubyzip gem dependency' do
      expect(described_class.gem_name).to eq('rubyzip')
    end
  end

  describe Legion::Data::Extract::Handlers::Xlsx do
    it 'is registered for :xlsx type' do
      expect(Legion::Data::Extract::Handlers::Base.for_type(:xlsx)).to eq(described_class)
    end

    it 'declares rubyXL gem dependency' do
      expect(described_class.gem_name).to eq('rubyXL')
    end
  end

  describe Legion::Data::Extract::Handlers::Html do
    it 'is registered for :html type' do
      expect(Legion::Data::Extract::Handlers::Base.for_type(:html)).to eq(described_class)
    end

    it 'declares nokogiri gem dependency' do
      expect(described_class.gem_name).to eq('nokogiri')
    end

    context 'when nokogiri is available' do
      it 'extracts text from HTML string' do
        f = Tempfile.new(['test', '.html'])
        f.write('<html><head><title>Test</title></head><body><p>Hello World</p><script>var x=1;</script></body></html>')
        f.flush
        result = described_class.extract(f.path)
        if result[:text]
          expect(result[:text]).to include('Hello World')
          expect(result[:text]).not_to include('var x=1')
          expect(result[:metadata][:title]).to eq('Test')
        else
          expect(result[:error]).to eq(:gem_not_installed)
        end
      ensure
        f&.close!
      end
    end
  end
end
