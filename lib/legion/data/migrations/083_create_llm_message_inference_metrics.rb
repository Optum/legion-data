# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_message_inference_metrics) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: false, on_delete: :cascade
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: true, on_delete: :set_null
      String :provider, size: 128
      String :model_key, size: 255
      String :tier, size: 64
      Integer :input_tokens, null: false, default: 0
      Integer :output_tokens, null: false, default: 0
      Integer :thinking_tokens, null: false, default: 0
      Integer :total_tokens, null: false, default: 0
      Integer :latency_ms, null: false, default: 0
      Integer :wall_clock_ms, null: false, default: 0
      BigDecimal :cost_usd, size: [20, 8], null: false, default: 0
      String :currency, size: 3, null: false, default: 'USD'
      String :cost_center, size: 128
      String :budget_key, size: 128
      DateTime :recorded_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :message_inference_request_id
      index :message_inference_response_id
      index %i[provider model_key]
      index :cost_center
      index :budget_key
      index :recorded_at
      index %i[cost_center recorded_at]
    end
  end
end
