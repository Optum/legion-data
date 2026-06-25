# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/encryption/key_provider'

RSpec.describe Legion::Data::Encryption::KeyProvider do
  let(:provider) { described_class.new }

  describe '#key_for' do
    it 'returns 32-byte key for default' do
      key = provider.key_for
      expect(key.bytesize).to eq(32)
    end

    it 'caches keys' do
      key1 = provider.key_for
      key2 = provider.key_for
      expect(key1).to equal(key2)
    end

    it 'returns different cache entries for different tenants' do
      key1 = provider.key_for(tenant_id: nil)
      key2 = provider.key_for(tenant_id: 'tenant-a')
      expect(key1).not_to eq(key2) if defined?(Legion::Crypt::PartitionKeys)
    end
  end

  describe '#clear_cache!' do
    it 'empties the key cache' do
      provider.key_for
      provider.clear_cache!
      expect(provider.instance_variable_get(:@key_cache)).to be_empty
    end
  end
end
