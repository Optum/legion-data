# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identities) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :principal_id, :portable_identity_principals, null: false, on_delete: :cascade
      foreign_key :provider_id, :portable_identity_providers, null: false, on_delete: :cascade
      String :provider_identity_key, size: 255, null: false
      String :profile_ciphertext, text: true
      TrueClass :active, null: false, default: true
      DateTime :last_authenticated_at
      String :account_type, size: 64, null: false, default: 'primary'
      String :qualifier, size: 255
      TrueClass :is_default, null: false, default: false
      String :link_evidence, text: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[principal_id provider_id provider_identity_key]
      index :uuid
      index :principal_id
      index :provider_id
      index :provider_identity_key
      index %i[provider_id provider_identity_key]
      index :active
      index :is_default
    end
  end
end
