# frozen_string_literal: true

Sequel.migration do
  up do
    return unless adapter_scheme == :postgres

    create_table(:identity_providers) do
      column :id, :uuid, default: Sequel.lit("gen_random_uuid()"), primary_key: true
      String :name, null: false, unique: true
      String :provider_type, null: false  # authenticate, profile, fallback
      String :facing, null: false         # human, machine, both
      Integer :priority, null: false, default: 100
      Integer :trust_weight, null: false, default: 50
      column :capabilities, :"text[]", default: Sequel.lit("'{}'")
      String :source, null: false, default: 'gem'  # gem, db
      TrueClass :enabled, null: false, default: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    return unless adapter_scheme == :postgres

    drop_table?(:identity_providers)
  end
end
