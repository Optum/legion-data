# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_message_inference_requests) do
      set_column_allow_null :context_tokens
    end
  end

  down do
    alter_table(:llm_message_inference_requests) do
      set_column_not_null :context_tokens
    end
  end
end
