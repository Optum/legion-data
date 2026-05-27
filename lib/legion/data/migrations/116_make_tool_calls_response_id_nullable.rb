# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      drop_index %i[message_inference_response_id tool_call_index], name: :llm_tool_calls_message_inference_response_id_tool_call_index_key
      set_column_allow_null :message_inference_response_id
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      set_column_not_null :message_inference_response_id
      add_unique_constraint %i[message_inference_response_id tool_call_index],
                            name: :llm_tool_calls_message_inference_response_id_tool_call_index_key
    end
  end
end
