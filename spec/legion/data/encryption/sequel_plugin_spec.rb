# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/encryption/sequel_plugin'

RSpec.describe Legion::Data::Encryption::SequelPlugin do
  describe 'ClassMethods' do
    let(:klass) do
      Class.new do
        extend Legion::Data::Encryption::SequelPlugin::ClassMethods
      end
    end

    it 'tracks encrypted columns' do
      expect(klass.encrypted_columns).to be_a(Hash)
    end

    it 'provides key provider' do
      expect(klass.encryption_key_provider).to be_a(Legion::Data::Encryption::KeyProvider)
    end
  end
end
