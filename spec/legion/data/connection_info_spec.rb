# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Legion::Data::Connection health check methods' do
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
      # fallback_active should match the class method
      expect(info[:fallback_active]).to eq(Legion::Data::Connection.fallback_active?)
    end
  end

  describe '.fallback_active?' do
    it 'returns a boolean' do
      expect(Legion::Data::Connection.fallback_active?).to be(true).or be(false)
    end

    it 'returns true when configured adapter differs from actual' do
      # In test environments without PG, fallback to SQLite is expected
      configured = Legion::Settings[:data][:adapter]&.to_sym rescue nil
      if configured == :postgres && Legion::Data::Connection.connection_info[:adapter] == :sqlite
        expect(Legion::Data::Connection.fallback_active?).to eq(true)
      end
    end
  end
end
