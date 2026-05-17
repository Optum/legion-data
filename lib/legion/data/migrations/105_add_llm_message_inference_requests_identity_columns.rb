# frozen_string_literal: true

# llm_message_inference_requests already has caller_principal_id and caller_identity_id (079).
# Add only the two missing standardized columns: access_scope and identity_canonical_name.
# Existing columns are NOT renamed — they are in active use by lex-llm-ledger.

Sequel.migration do
  up do
    alter_table(:llm_message_inference_requests) do
      add_column :access_scope, String, size: 20, null: false, default: 'global'
      add_column :identity_canonical_name, String, size: 255, null: true
    end

    run 'CREATE INDEX IF NOT EXISTS idx_inference_requests_access_scope ON llm_message_inference_requests (access_scope)'
  end

  down do
    run 'DROP INDEX IF EXISTS idx_inference_requests_access_scope'

    alter_table(:llm_message_inference_requests) do
      drop_column :access_scope
      drop_column :identity_canonical_name
    end
  end
end
