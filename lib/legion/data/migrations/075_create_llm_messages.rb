# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_messages) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :conversation_id, :llm_conversations, null: false, on_delete: :cascade
      foreign_key :parent_message_id, :llm_messages, null: true, on_delete: :set_null
      Integer :message_inference_request_id
      Integer :message_inference_response_id
      Integer :tool_call_id
      Integer :seq, null: false
      String :role, size: 32, null: false
      String :content_type, size: 64, null: false, default: 'text'
      String :content, text: true
      Integer :input_tokens, null: false, default: 0
      Integer :output_tokens, null: false, default: 0
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[conversation_id seq]
      index :uuid
      index :conversation_id
      index :parent_message_id
      index :message_inference_request_id
      index :message_inference_response_id
      index :tool_call_id
      index %i[conversation_id role]
      index :created_at
    end
  end
end
