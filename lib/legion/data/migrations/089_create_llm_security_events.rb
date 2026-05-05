# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_security_events) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :conversation_id, :llm_conversations, null: true, on_delete: :set_null
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: true, on_delete: :set_null
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: true, on_delete: :set_null
      foreign_key :tool_call_id, :llm_tool_calls, null: true, on_delete: :set_null
      foreign_key :tool_call_attempt_id, :llm_tool_call_attempts, null: true, on_delete: :set_null
      foreign_key :policy_evaluation_id, :llm_policy_evaluations, null: true, on_delete: :set_null
      String :event_type, size: 128, null: false
      String :severity, size: 32, null: false, default: 'info'
      String :status, size: 64, null: false, default: 'open'
      String :description, text: true
      DateTime :detected_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :conversation_id
      index :message_inference_request_id
      index :message_inference_response_id
      index :tool_call_id
      index :tool_call_attempt_id
      index :policy_evaluation_id
      index :event_type
      index :severity
      index :detected_at
    end
  end
end
