# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      drop_constraint(:llm_tool_calls_message_inference_response_id_tool_call_index_key, type: :unique)
      add_unique_constraint [:uuid], name: :llm_tool_calls_uuid_unique
      set_column_allow_null :message_inference_response_id
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      set_column_not_null :message_inference_response_id
      drop_constraint(:llm_tool_calls_uuid_unique, type: :unique)
      add_unique_constraint [:uuid]
      add_unique_constraint %i[message_inference_response_id tool_call_index]
    end
  end
end
