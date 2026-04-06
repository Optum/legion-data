# frozen_string_literal: true

Sequel.migration do
  up do
    return unless adapter_scheme == :postgres

    create_table(:identities) do
      column :id, :uuid, default: Sequel.lit("gen_random_uuid()"), primary_key: true
      foreign_key :principal_id, :principals, type: :uuid, null: false, on_delete: :cascade
      foreign_key :provider_id, :identity_providers, type: :uuid, null: false, on_delete: :cascade
      String :provider_identity, null: false  # external ID from provider
      column :profile, :jsonb, default: Sequel.lit("'{}'::jsonb")
      TrueClass :active, null: false, default: true
      DateTime :last_authenticated_at
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique [:principal_id, :provider_id, :provider_identity]
    end

    # Partial unique index: only one active identity per provider+provider_identity
    run "CREATE UNIQUE INDEX identities_active_provider_uniq ON identities (provider_id, provider_identity) WHERE active = true"

    add_index :identities, :principal_id
    add_index :identities, :provider_id
  end

  down do
    return unless adapter_scheme == :postgres

    drop_table?(:identities)
  end
end
