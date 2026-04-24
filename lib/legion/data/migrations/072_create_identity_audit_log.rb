# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    create_table(:identity_audit_log) do
      column :id, :uuid, default: Sequel.lit('gen_random_uuid()'), primary_key: true
      foreign_key :principal_id, :principals, type: :uuid, on_delete: :set_null
      foreign_key :identity_id, :identities, type: :uuid, on_delete: :set_null
      String :provider_name, null: false
      String :event_type, null: false
      String :trust_level
      column :detail, :jsonb, null: false, default: Sequel.lit("'{}'")
      String :node_id
      String :session_id
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    add_index :identity_audit_log, :principal_id
    add_index :identity_audit_log, :event_type
    add_index :identity_audit_log, :created_at
    add_index :identity_audit_log, %i[principal_id event_type created_at]
  end

  down do
    next unless adapter_scheme == :postgres

    drop_table?(:identity_audit_log)
  end
end
