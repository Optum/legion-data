# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identity_providers) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      String :name, size: 255, null: false, unique: true
      String :provider_type, size: 64, null: false
      String :facing, size: 32, null: false
      Integer :priority, null: false, default: 100
      Integer :trust_weight, null: false, default: 50
      String :source, size: 64, null: false, default: 'gem'
      TrueClass :enabled, null: false, default: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :name
      index :provider_type
      index :enabled
    end

    create_table(:portable_identity_provider_capabilities) do
      primary_key :id
      foreign_key :provider_id, :portable_identity_providers, null: false, on_delete: :cascade
      String :capability_key, size: 128, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[provider_id capability_key]
      index :provider_id
      index :capability_key
    end
  end
end
