# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_messages) do
      add_column :access_scope, String, size: 20, null: false, default: 'global'
      add_column :identity_principal_id, Integer, null: true
      add_column :identity_id, Integer, null: true
      add_column :identity_canonical_name, String, size: 255, null: true
    end

    run 'CREATE INDEX IF NOT EXISTS idx_messages_access_scope ON llm_messages (access_scope)'
    run 'CREATE INDEX IF NOT EXISTS idx_messages_identity_principal_id ON llm_messages (identity_principal_id) WHERE identity_principal_id IS NOT NULL'
  end

  down do
    run 'DROP INDEX IF EXISTS idx_messages_access_scope'
    run 'DROP INDEX IF EXISTS idx_messages_identity_principal_id'

    alter_table(:llm_messages) do
      drop_column :access_scope
      drop_column :identity_principal_id
      drop_column :identity_id
      drop_column :identity_canonical_name
    end
  end
end
