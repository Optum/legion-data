# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe 'Legion::Data::Connection' do
  after(:each) do
    Legion::Data::Connection.shutdown
  end

  it 'can setup' do
    expect { Legion::Data::Connection.setup }.not_to raise_error
    # expect(Legion::Data::Connection.adapter).to eq :mysql2
    expect(Legion::Settings[:data][:connected]).to eq true
  end

  it 'can shutdown' do
    expect { Legion::Data::Connection.shutdown }.not_to raise_error
    expect(Legion::Settings[:data][:connected]).to eq false
  end

  it 'has creds_builder' do
    creds = Legion::Data::Connection.creds_builder
    expect(creds).to be_a Hash
    expect(creds[:database]).to eq 'legionio.db'
  end

  it 'can setup with logger' do
    Legion::Settings[:data][:log] = true
    Legion::Settings[:data][:sql_log_level] = 'debug'
    Legion::Settings[:data][:log_warn_duration] = 42
    Legion::Data::Connection.setup
    expect(Legion::Data::Connection.sequel.sql_log_level).to eq :debug
    expect(Legion::Data::Connection.sequel.log_warn_duration).to eq 42
  end

  it 'can run creds_builder' do
    expect(Legion::Data::Connection.creds_builder).to be_a Hash
  end

  it 'using a tagged SlowQueryLogger' do
    Legion::Data::Connection.setup
    expect(Legion::Data::Connection.sequel.loggers).to be_a Array
    expect(Legion::Data::Connection.sequel.loggers.count).to be > 0
    expect(Legion::Data::Connection.sequel.loggers.first).to be_a Legion::Data::Connection::SlowQueryLogger
    expect(Legion::Data::Connection.sequel.loggers.first.tagged.segments).to eq(%w[data connection])
  end

  it 'uses other things' do
    Legion::Data::Connection.setup
    expect(Legion::Settings[:data][:connected]).to eq true
    expect(Legion::Data::Connection.sequel.log_warn_duration)
      .to eq Legion::Settings[:data][:log_warn_duration]
    expect(Legion::Data::Connection.sequel.sql_log_level).to eq Legion::Settings[:data][:sql_log_level].to_sym
  end

  describe 'connection_validation_timeout default' do
    it 'defaults to -1 so every checkout validates liveness' do
      expect(Legion::Data::Settings.default[:connection_validation_timeout]).to eq(-1)
    end
  end

  describe 'preconnect default' do
    it 'defaults to false to avoid background thread noise on failed network connects' do
      expect(Legion::Data::Settings.default[:preconnect]).to eq(false)
    end
  end

  describe Legion::Data::Connection::QueryFileLogger do
    around do |example|
      Dir.mktmpdir('legion-data-query-log') do |dir|
        @query_log_path = File.join(dir, 'query.log')
        example.run
      end
    end

    it 'ignores debug writes after close without warning' do
      logger = described_class.new(@query_log_path)
      logger.close

      expect(logger).not_to receive(:handle_exception)
      expect { logger.debug('SELECT 1') }.not_to raise_error
    end

    it 'allows repeated close calls' do
      logger = described_class.new(@query_log_path)

      expect { 2.times { logger.close } }.not_to raise_error
    end
  end
end
