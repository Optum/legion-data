# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_message_inference_responses) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: false, on_delete: :cascade
      foreign_key :response_message_id, :llm_messages, null: true, on_delete: :set_null
      String :provider, size: 128
      String :model_key, size: 255
      String :tier, size: 64
      String :runner_ref, size: 128
      String :provider_response_ref, size: 255
      String :status, size: 64, null: false, default: 'created'
      String :finish_reason, size: 128
      String :error_category, size: 128
      String :error_code, size: 128
      String :error_message, text: true
      Integer :latency_ms, null: false, default: 0
      Integer :wall_clock_ms, null: false, default: 0
      String :response_capture_mode, size: 64, null: false, default: 'metadata_only'
      String :response_content_hash, size: 128
      String :response_json, text: true
      String :response_thinking_json, text: true
      DateTime :responded_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :message_inference_request_id
      index :response_message_id
      index %i[provider model_key]
      index :runner_ref
      index :provider_response_ref
      index :status
      index :responded_at
    end
  end
end
