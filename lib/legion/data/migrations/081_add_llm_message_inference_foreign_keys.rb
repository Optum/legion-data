# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_messages) do
      add_foreign_key [:message_inference_request_id], :llm_message_inference_requests, key: :id, on_delete: :set_null
      add_foreign_key [:message_inference_response_id], :llm_message_inference_responses, key: :id, on_delete: :set_null
    end
  end

  down do
    alter_table(:llm_messages) do
      drop_foreign_key [:message_inference_response_id]
      drop_foreign_key [:message_inference_request_id]
    end
  end
end
