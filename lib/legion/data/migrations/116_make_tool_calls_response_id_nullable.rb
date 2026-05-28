# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      set_column_allow_null :message_inference_response_id
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      set_column_not_null :message_inference_response_id
    end
  end
end
