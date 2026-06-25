# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_message_inference_requests) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :conversation_id, :llm_conversations, null: false, on_delete: :cascade
      foreign_key :latest_message_id, :llm_messages, null: true, on_delete: :set_null
      Integer :caller_principal_id
      Integer :caller_identity_id
      String :runtime_caller_type, size: 64
      String :request_ref, size: 128
      String :correlation_ref, size: 128
      String :exchange_ref, size: 128
      String :request_type, size: 64, null: false, default: 'chat'
      String :status, size: 64, null: false, default: 'created'
      Integer :context_message_count, null: false, default: 0
      Integer :context_tokens, null: false, default: 0
      Integer :token_budget, null: false, default: 0
      String :curation_strategy, size: 128
      Integer :injected_tool_count, null: false, default: 0
      String :tool_policy, size: 128
      String :request_capture_mode, size: 64, null: false, default: 'metadata_only'
      String :request_content_hash, size: 128
      String :request_json, text: true
      String :classification_level, size: 64
      String :rbac_decision, size: 64
      String :cost_center, size: 128
      String :budget_key, size: 128
      DateTime :requested_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :conversation_id
      index :latest_message_id
      index :caller_principal_id
      index :caller_identity_id
      index :request_ref
      index :correlation_ref
      index :exchange_ref
      index :status
      index %i[cost_center requested_at]
      index :requested_at
    end
  end
end
