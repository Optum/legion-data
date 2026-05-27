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
      drop_index :conversation_id
      drop_foreign_key :conversation_id
    end
  end
end
