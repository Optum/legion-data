# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_conversation_compactions) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :conversation_id, :llm_conversations, null: false, on_delete: :cascade
      foreign_key :triggered_by_message_inference_request_id, :llm_message_inference_requests, null:      true,
                                                                                               on_delete: :set_null
      foreign_key :replaces_message_from_id, :llm_messages, null: true, on_delete: :set_null
      foreign_key :replaces_message_to_id, :llm_messages, null: true, on_delete: :set_null
      String :strategy, size: 128
      String :status, size: 64, null: false, default: 'created'
      Integer :source_message_count, null: false, default: 0
      Integer :source_token_count, null: false, default: 0
      Integer :compacted_token_count, null: false, default: 0
      String :content_hash, size: 128
      String :summary, text: true
      String :error_message, text: true
      DateTime :compacted_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :conversation_id
      index :triggered_by_message_inference_request_id
      index :status
      index :compacted_at
    end
  end
end
