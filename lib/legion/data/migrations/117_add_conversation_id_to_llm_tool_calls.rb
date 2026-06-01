# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      add_foreign_key :conversation_id, :llm_conversations, null: true, on_delete: :set_null, on_update: :cascade
      add_index :conversation_id
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      drop_column :conversation_id
      # On SQLite, drop_column triggers table recreation which silently destroys
      # partial indexes. Recreate the one from migration 109.
      add_index :identity_principal_id,
                name: :idx_tool_calls_identity_principal_id,
                where: Sequel.negate(identity_principal_id: nil),
                if_not_exists: true
    end
  end
end
