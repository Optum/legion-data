# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      add_column :access_scope, String, size: 20, null: false, default: 'global'
      add_column :identity_principal_id, Integer, null: true
      add_column :identity_id, Integer, null: true
      add_column :identity_canonical_name, String, size: 255, null: true
    end

    run 'CREATE INDEX IF NOT EXISTS idx_tool_calls_access_scope ON llm_tool_calls (access_scope)'
    run 'CREATE INDEX IF NOT EXISTS idx_tool_calls_identity_principal_id ON llm_tool_calls (identity_principal_id) WHERE identity_principal_id IS NOT NULL'
  end

  down do
    run 'DROP INDEX IF EXISTS idx_tool_calls_access_scope'
    run 'DROP INDEX IF EXISTS idx_tool_calls_identity_principal_id'

    alter_table(:llm_tool_calls) do
      drop_column :access_scope
      drop_column :identity_principal_id
      drop_column :identity_id
      drop_column :identity_canonical_name
    end
  end
end
