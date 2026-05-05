# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_policy_evaluations) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :conversation_id, :llm_conversations, null: true, on_delete: :set_null
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: true, on_delete: :set_null
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: true, on_delete: :set_null
      String :policy_key, size: 128, null: false
      String :policy_version, size: 64
      String :evaluation_type, size: 64, null: false
      String :decision, size: 64, null: false
      String :enforcement_action, size: 64
      String :classification_level, size: 64
      TrueClass :contains_phi, null: false, default: false
      TrueClass :contains_pii, null: false, default: false
      String :reason_code, size: 128
      String :reason, text: true
      DateTime :evaluated_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :conversation_id
      index :message_inference_request_id
      index :message_inference_response_id
      index :policy_key
      index :decision
      index :evaluated_at
    end
  end
end
