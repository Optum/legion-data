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

  describe 'integration' do
    let(:db) do
      Sequel.sqlite.tap do |database|
        database.create_table(:encrypted_records) do
          primary_key :id
          String :tenant_id
          column :secret, 'BLOB'
          column :tenant_secret, 'BLOB'
        end
      end
    end

    let(:model_class) do
      Class.new(Sequel::Model(db[:encrypted_records])) do
        plugin Legion::Data::Encryption::SequelPlugin
        encrypted_column :secret
        encrypted_column :tenant_secret, key_scope: :tenant
      end
    end

    after do
      db.disconnect
    end

    it 'decrypts a newly-created persisted row' do
      record = model_class.create(secret: 'hello')

      expect(model_class[record.id].secret).to eq('hello')
    end

    it 're-encrypts newly-created rows with their persisted primary key' do
      record = model_class.create(secret: 'hello')
      blob = db[:encrypted_records].where(id: record.id).get(:secret)
      key = model_class.encryption_key_provider.key_for

      expect(
        Legion::Data::Encryption::Cipher.decrypt(
          blob,
          key: key,
          aad: Legion::Data::Encryption::SequelPlugin.aad_for(
            table_name:  :encrypted_records,
            primary_key: record.id,
            column:      :secret
          )
        )
      ).to eq('hello')

      expect do
        Legion::Data::Encryption::Cipher.decrypt(
          blob,
          key: key,
          aad: Legion::Data::Encryption::SequelPlugin.aad_for(
            table_name:  :encrypted_records,
            primary_key: 0,
            column:      :secret
          )
        )
      end.to raise_error(OpenSSL::Cipher::CipherError)
    end

    it 'still reads rows encrypted with the legacy pre-persist AAD' do
      key = model_class.encryption_key_provider.key_for
      blob = Legion::Data::Encryption::Cipher.encrypt(
        'hello',
        key: key,
        aad: Legion::Data::Encryption::SequelPlugin.aad_for(
          table_name:  :encrypted_records,
          primary_key: 0,
          column:      :secret
        )
      )
      id = db[:encrypted_records].insert(secret: Sequel.blob(blob))

      expect(model_class[id].secret).to eq('hello')
    end

    it 'decrypts updates on already-persisted rows' do
      record = model_class.create(secret: 'hello')

      record.update(secret: 'world')

      expect(model_class[record.id].secret).to eq('world')
    end

    it 'preserves nil encrypted columns' do
      record = model_class.create(secret: nil, tenant_secret: nil)
      reloaded = model_class[record.id]

      expect(reloaded.secret).to be_nil
      expect(reloaded.tenant_secret).to be_nil
    end

    it 'decrypts tenant-scoped columns after persistence' do
      provider = instance_double(Legion::Data::Encryption::KeyProvider)
      allow(provider).to receive(:key_for) do |tenant_id: nil|
        OpenSSL::Digest.digest('SHA256', "tenant:#{tenant_id}")
      end
      model_class.instance_variable_set(:@encryption_key_provider, provider)

      record = model_class.create(tenant_id: 'tenant-a', tenant_secret: 'hello')
      reloaded = model_class[record.id]

      expect(reloaded.tenant_secret).to eq('hello')
      expect(provider).to have_received(:key_for).with(tenant_id: 'tenant-a').at_least(:once)
    end
  end
end
