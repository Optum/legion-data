# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/encryption/cipher'

RSpec.describe Legion::Data::Encryption::Cipher do
  let(:key) { OpenSSL::Random.random_bytes(32) }
  let(:plaintext) { 'sensitive data here' }
  let(:aad) { 'tasks:1:payload' }

  describe '.encrypt / .decrypt' do
    it 'round-trips plaintext' do
      blob = described_class.encrypt(plaintext, key: key, aad: aad)
      result = described_class.decrypt(blob, key: key, aad: aad)
      expect(result).to eq(plaintext)
    end

    it 'produces different ciphertext each time (random IV)' do
      blob1 = described_class.encrypt(plaintext, key: key)
      blob2 = described_class.encrypt(plaintext, key: key)
      expect(blob1).not_to eq(blob2)
    end

    it 'fails with wrong key' do
      blob = described_class.encrypt(plaintext, key: key, aad: aad)
      wrong_key = OpenSSL::Random.random_bytes(32)
      expect { described_class.decrypt(blob, key: wrong_key, aad: aad) }.to raise_error(OpenSSL::Cipher::CipherError)
    end

    it 'fails with wrong AAD' do
      blob = described_class.encrypt(plaintext, key: key, aad: aad)
      expect { described_class.decrypt(blob, key: key, aad: 'wrong') }.to raise_error(OpenSSL::Cipher::CipherError)
    end

    it 'raises on truncated data' do
      expect { described_class.decrypt('short', key: key) }.to raise_error(ArgumentError, /too short/)
    end
  end
end
