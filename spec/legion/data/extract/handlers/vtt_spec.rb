# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/extract/handlers/vtt'

RSpec.describe Legion::Data::Extract::Handlers::Vtt do
  describe '.extract' do
    let(:vtt_content) do
      <<~VTT
        WEBVTT

        00:00:01.000 --> 00:00:05.000
        <v Alice>Hello everyone, let's get started.

        00:00:05.500 --> 00:00:10.000
        <v Bob>Thanks Alice. I have the Q3 numbers ready.

        00:00:10.500 --> 00:00:15.000
        <v Alice>Great, please share them with the group.
      VTT
    end

    it 'extracts text from VTT content' do
      result = described_class.extract(vtt_content)
      expect(result[:text]).to include('Hello everyone')
      expect(result[:text]).to include('Q3 numbers')
    end

    it 'preserves speaker attribution by default' do
      result = described_class.extract(vtt_content)
      expect(result[:text]).to include('Alice:')
      expect(result[:text]).to include('Bob:')
    end

    it 'strips speaker tags when preserve_speakers is false' do
      result = described_class.extract(vtt_content, preserve_speakers: false)
      expect(result[:text]).not_to include('Alice:')
      expect(result[:text]).to include('Hello everyone')
    end

    it 'strips WebVTT timestamps from output' do
      result = described_class.extract(vtt_content)
      expect(result[:text]).not_to match(/\d{2}:\d{2}:\d{2}.\d{3} -->/)
    end

    it 'handles input via file path' do
      require 'tempfile'
      f = Tempfile.new(['test', '.vtt'])
      f.write(vtt_content)
      f.close
      result = described_class.extract(f.path)
      expect(result[:text]).to include('Hello everyone')
      f.unlink
    end

    it 'returns error hash on failure' do
      result = described_class.extract('/nonexistent/path.vtt')
      expect(result[:text]).to be_nil
      expect(result[:error]).to be_a(String)
    end
  end

  describe '.type' do
    it 'returns :vtt' do
      expect(described_class.type).to eq(:vtt)
    end
  end

  describe '.extensions' do
    it 'includes .vtt' do
      expect(described_class.extensions).to include('.vtt')
    end
  end
end
