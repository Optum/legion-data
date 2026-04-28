# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe 'Legion::Data::Connection health check methods' do
  let(:test_db) { 'legionio_connection_info_test.db' }

  before(:each) do
    @saved_adapter = Legion::Settings[:data][:adapter]
    @saved_creds = Legion::Settings[:data][:creds].dup
    @saved_dev_mode = Legion::Settings[:data][:dev_mode]
    @saved_dev_fallback = Legion::Settings[:data][:dev_fallback]
    @saved_connected = Legion::Settings[:data][:connected]
    @saved_ivar_adapter = described_class.instance_variable_get(:@adapter)
    @saved_ivar_sequel = described_class.instance_variable_get(:@sequel)
    @saved_ivar_fallback_active = described_class.instance_variable_get(:@fallback_active)
  end

  after(:each) do
    begin
      described_class.shutdown
    rescue StandardError
      nil
    end

    described_class.instance_variable_set(:@adapter, @saved_ivar_adapter)
    described_class.instance_variable_set(:@sequel, @saved_ivar_sequel)
    described_class.instance_variable_set(:@fallback_active, @saved_ivar_fallback_active)
    Legion::Settings[:data][:adapter] = @saved_adapter
    Legion::Settings[:data][:creds] = @saved_creds
    Legion::Settings[:data][:dev_mode] = @saved_dev_mode
    Legion::Settings[:data][:dev_fallback] = @saved_dev_fallback
    Legion::Settings[:data][:connected] = @saved_connected
    FileUtils.rm_f(test_db)
  end

  describe '.connection_info' do
    it 'returns a hash with adapter and connection state' do
      info = Legion::Data::Connection.connection_info
      expect(info).to be_a(Hash)
      expect(info).to have_key(:adapter)
      expect(info).to have_key(:connected)
      expect(info).to have_key(:fallback_active)
    end

    it 'reports the current adapter' do
      info = Legion::Data::Connection.connection_info
      expect(%i[sqlite postgres mysql2]).to include(info[:adapter])
    end

    it 'reports consistent fallback state' do
      info = Legion::Data::Connection.connection_info
      expect(info[:fallback_active]).to eq(Legion::Data::Connection.fallback_active?)
    end
  end

  describe '.fallback_active?' do
    it 'returns a boolean' do
      expect(Legion::Data::Connection.fallback_active?).to be(true).or be(false)
    end

    it 'returns true after a deterministic network adapter fallback' do
      described_class.instance_variable_set(:@adapter, nil)
      described_class.instance_variable_set(:@sequel, nil)
      described_class.instance_variable_set(:@fallback_active, false)
      Legion::Settings[:data][:adapter] = 'postgres'
      Legion::Settings[:data][:dev_mode] = true
      Legion::Settings[:data][:dev_fallback] = true
      Legion::Settings[:data][:creds] = { database: test_db }

      allow(Sequel).to receive(:connect).and_wrap_original do |original, *args, **kwargs|
        options = kwargs.empty? ? args.last : kwargs
        raise Sequel::DatabaseConnectionError, 'connection failed' if options[:adapter] == :postgres

        original.call(*args, **kwargs)
      end

      described_class.setup
      info = described_class.connection_info

      expect(described_class.fallback_active?).to be(true)
      expect(info[:adapter]).to eq(:sqlite)
      expect(info[:configured_adapter]).to eq(:postgres)
      expect(info[:fallback_active]).to be(true)
    end
  end
end
