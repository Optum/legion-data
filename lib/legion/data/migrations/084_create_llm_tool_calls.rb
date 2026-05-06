# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_tool_calls) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: false, on_delete: :cascade
      foreign_key :requested_by_message_id, :llm_messages, null: true, on_delete: :set_null
      foreign_key :result_message_id, :llm_messages, null: true, on_delete: :set_null
      Integer :tool_call_index, null: false, default: 0
      String :provider_tool_call_ref, size: 255
      String :tool_name, size: 255, null: false
      String :tool_source_type, size: 128
      String :tool_source_server, size: 255
      String :status, size: 64, null: false, default: 'requested'
      DateTime :requested_at
      DateTime :completed_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[message_inference_response_id tool_call_index]
      index :uuid
      index :message_inference_response_id
      index :requested_by_message_id
      index :result_message_id
      index :provider_tool_call_ref
      index :tool_name
      index :status
      index :requested_at
    end
  end
end
