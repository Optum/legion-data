# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_route_attempts) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: false, on_delete: :cascade
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: true, on_delete: :set_null
      Integer :attempt_no, null: false
      String :provider, size: 128
      String :model_key, size: 255
      String :tier, size: 64
      String :route_target, size: 255
      String :status, size: 64, null: false
      String :failure_reason, text: true
      Integer :latency_ms, null: false, default: 0
      DateTime :started_at
      DateTime :ended_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[message_inference_request_id attempt_no]
      index :uuid
      index :message_inference_request_id
      index :message_inference_response_id
      index %i[provider model_key]
      index :status
      index :started_at
    end
  end
end
