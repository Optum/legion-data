# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identity_audit_log) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :principal_id, :portable_identity_principals, on_delete: :set_null
      foreign_key :identity_id, :portable_identities, on_delete: :set_null
      String :provider_name, size: 255, null: false
      String :event_type, size: 128, null: false
      String :trust_level, size: 64
      String :detail_payload, text: true
      String :node_ref, size: 255
      String :session_ref, size: 255
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :principal_id
      index :identity_id
      index :event_type
      index :created_at
      index %i[principal_id event_type created_at]
    end
  end
end
