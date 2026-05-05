# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_messages) do
      add_foreign_key [:tool_call_id], :llm_tool_calls, key: :id, on_delete: :set_null
    end
  end

  down do
    alter_table(:llm_messages) do
      drop_foreign_key [:tool_call_id]
    end
  end
end
