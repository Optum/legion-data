require 'spec_helper'

RSpec.describe 'Legion::Data::Connection' do
  after(:each) do
    Legion::Data::Connection.shutdown
  end

  it 'can setup' do
    expect { Legion::Data::Connection.setup }.not_to raise_exception
    # expect(Legion::Data::Connection.adapter).to eq :mysql2
    expect(Legion::Settings[:data][:connected]).to eq true
  end

  it 'can shutdown' do
    expect { Legion::Data::Connection.shutdown }.not_to raise_exception
    expect(Legion::Settings[:data][:connected]).to eq false
  end

  it 'has default_creds' do
    expect(Legion::Data::Connection.default_creds).to be_a Hash
    expect(Legion::Data::Connection.default_creds[:host]).to eq '127.0.0.1'
    expect(Legion::Data::Connection.default_creds[:port]).to eq 3306
    expect(Legion::Data::Connection.default_creds[:username]).to eq 'legion'
    expect(Legion::Data::Connection.default_creds[:password]).to eq 'legion'
    expect(Legion::Data::Connection.default_creds[:database]).to eq 'legion'
    expect(Legion::Data::Connection.default_creds[:preconnect]).to eq nil
    expect(Legion::Data::Connection.default_creds[:max_connections]).to eq 4
  end

  it 'can setup with logger' do
    Legion::Settings[:data][:connection][:log] = true
    Legion::Settings[:data][:connection][:sql_log_level] = 'debug'
    Legion::Settings[:data][:connection][:log_warn_duration] = 42
    Legion::Data::Connection.setup
    expect(Legion::Data::Connection.sequel.sql_log_level).to eq 'debug'
    expect(Legion::Data::Connection.sequel.log_warn_duration).to eq 42
  end

  it 'can run creds_builder' do
    expect(Legion::Data::Connection.creds_builder).to be_a Hash
  end

  it 'using the Legion::Logging logger' do
    Legion::Data::Connection.setup
    expect(Legion::Data::Connection.sequel.loggers).to be_a Array
    expect(Legion::Data::Connection.sequel.loggers.count).to be > 0
    expect(Legion::Data::Connection.sequel.loggers).to include Legion::Logging
  end

  it 'uses other things' do
    Legion::Data::Connection.setup
    expect(Legion::Settings[:data][:connected]).to eq true
    expect(Legion::Data::Connection.sequel.log_warn_duration)
      .to eq Legion::Settings[:data][:connection][:log_warn_duration]
    expect(Legion::Data::Connection.sequel.sql_log_level).to eq Legion::Settings[:data][:connection][:sql_log_level]
  end
end
