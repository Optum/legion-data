# frozen_string_literal: true

# llm_conversations already has principal_id and identity_id (077).
# Add only the two missing standardized columns: access_scope and identity_canonical_name.
# Existing columns are NOT renamed — they are in active use by lex-llm-ledger.

Sequel.migration do
  up do
    alter_table(:llm_conversations) do
      add_column :access_scope, String, size: 20, null: false, default: 'global'
      add_column :identity_canonical_name, String, size: 255, null: true
      add_index :access_scope, name: :idx_conversations_access_scope
    end
  end

  down do
    alter_table(:llm_conversations) do
      drop_index :access_scope, name: :idx_conversations_access_scope
      drop_column :access_scope
      drop_column :identity_canonical_name
    end
  end
end
