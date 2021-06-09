require 'spec_helper'

RSpec.describe Legion::Data do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it 'has a version number' do
    expect(Legion::Data::VERSION).to be_a String
  end

  it 'can init' do
    expect { Legion::Data.setup }.not_to raise_exception
    expect(Legion::Settings[:data][:connected]).to eq true
  end

  describe Legion::Data.shutdown do
    it 'should not raise_error' do
      expect { Legion::Data.shutdown }.not_to raise_error
    end

    it 'should update Legion::Settings connection status' do
      Legion::Data.shutdown
      expect(Legion::Settings[:data][:connected]).to eq false
    end
  end

  it '.setup_cache' do
    expect(Legion::Settings[:data][:cache][:connected]).to eq false
    expect(Legion::Data.setup_cache).to eq nil
    expect(Legion::Settings[:data][:cache][:connected]).to eq false
  end
end
