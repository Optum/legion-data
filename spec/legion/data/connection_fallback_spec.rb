# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Legion::Data::Connection do
  describe 'dev mode fallback' do
    let(:test_db) { 'legionio_fallback_test.db' }

    before(:each) do
      @saved_adapter = Legion::Settings[:data][:adapter]
      @saved_creds = Legion::Settings[:data][:creds].dup
      @saved_dev_mode = Legion::Settings[:data][:dev_mode]
      @saved_dev_fallback = Legion::Settings[:data][:dev_fallback]
      @saved_connected = Legion::Settings[:data][:connected]
      @saved_ivar_adapter = described_class.instance_variable_get(:@adapter)
      @saved_ivar_sequel = described_class.instance_variable_get(:@sequel)

      described_class.instance_variable_set(:@adapter, nil)
      described_class.instance_variable_set(:@sequel, nil)
      Legion::Settings[:data][:connected] = false
    end

    after(:each) do
      begin
        described_class.shutdown
      rescue StandardError
        nil
      end
      described_class.instance_variable_set(:@adapter, @saved_ivar_adapter)
      described_class.instance_variable_set(:@sequel, @saved_ivar_sequel)
      Legion::Settings[:data][:adapter] = @saved_adapter
      Legion::Settings[:data][:creds] = @saved_creds
      Legion::Settings[:data][:dev_mode] = @saved_dev_mode
      Legion::Settings[:data][:dev_fallback] = @saved_dev_fallback
      Legion::Settings[:data][:connected] = @saved_connected
      FileUtils.rm_f(test_db)
    end

    context 'when dev_mode is true and network DB unreachable' do
      before do
        Legion::Settings[:data][:adapter] = 'mysql2'
        Legion::Settings[:data][:dev_mode] = true
        Legion::Settings[:data][:dev_fallback] = true
        Legion::Settings[:data][:creds] = { database: test_db }
        allow(Sequel).to receive(:connect).and_wrap_original do |original, *args, **kwargs|
          raise Sequel::DatabaseConnectionError, 'connection refused' if kwargs[:adapter] == :mysql2

          original.call(*args, **kwargs)
        end
      end

      it 'falls back to SQLite' do
        described_class.setup
        expect(described_class.adapter).to eq(:sqlite)
        expect(described_class.sequel).to be_a(Sequel::SQLite::Database)
      end
    end

    context 'when dev_mode is false and network DB unreachable' do
      before do
        Legion::Settings[:data][:adapter] = 'mysql2'
        Legion::Settings[:data][:dev_mode] = false
        Legion::Settings[:data][:creds] = { database: test_db }
        allow(Sequel).to receive(:connect).and_raise(Sequel::DatabaseConnectionError, 'connection refused')
      end

      it 'raises the connection error' do
        expect { described_class.setup }.to raise_error(Sequel::DatabaseConnectionError)
      end
    end

    context 'when dev_fallback is explicitly disabled' do
      before do
        Legion::Settings[:data][:adapter] = 'mysql2'
        Legion::Settings[:data][:dev_mode] = true
        Legion::Settings[:data][:dev_fallback] = false
        Legion::Settings[:data][:creds] = { database: test_db }
        allow(Sequel).to receive(:connect).and_raise(Sequel::DatabaseConnectionError, 'connection refused')
      end

      it 'raises the connection error' do
        expect { described_class.setup }.to raise_error(Sequel::DatabaseConnectionError)
      end
    end
  end
end
