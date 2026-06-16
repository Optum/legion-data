# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_message_inference_metrics) do
      add_column :request_message_estimated_tokens, Integer, null: false, default: 0
      add_column :loaded_history_estimated_tokens, Integer, null: false, default: 0
      add_column :curated_history_estimated_tokens, Integer, null: false, default: 0
      add_column :curation_saved_estimated_tokens, Integer, null: false, default: 0
      add_column :stripped_thinking_estimated_tokens, Integer, null: false, default: 0
      add_column :archived_history_estimated_tokens, Integer, null: false, default: 0
      add_column :archive_saved_estimated_tokens, Integer, null: false, default: 0
      add_column :context_window_saved_estimated_tokens, Integer, null: false, default: 0
      add_column :rag_injected_estimated_tokens, Integer, null: false, default: 0
      add_column :system_prompt_estimated_tokens, Integer, null: false, default: 0
      add_column :baseline_system_estimated_tokens, Integer, null: false, default: 0
      add_column :tool_definition_estimated_tokens, Integer, null: false, default: 0
      add_column :final_context_estimated_tokens, Integer, null: false, default: 0
      add_column :loaded_history_message_count, Integer, null: false, default: 0
      add_column :curated_history_message_count, Integer, null: false, default: 0
      add_column :archived_history_message_count, Integer, null: false, default: 0
      add_column :stripped_thinking_message_count, Integer, null: false, default: 0
      add_column :context_window_message_count_before, Integer, null: false, default: 0
      add_column :context_window_message_count_after, Integer, null: false, default: 0
      add_column :rag_entry_count, Integer, null: false, default: 0
      add_column :tool_definition_count, Integer, null: false, default: 0
      add_column :context_accounting_status, String, size: 64, null: false, default: 'missing'
      add_column :context_accounting_json, String, text: true
    end

    create_table(:llm_context_accounting_events) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :message_inference_request_id, :llm_message_inference_requests, null: false, on_delete: :cascade
      foreign_key :message_inference_response_id, :llm_message_inference_responses, null: true, on_delete: :set_null
      foreign_key :message_inference_metric_id, :llm_message_inference_metrics, null: true, on_delete: :set_null
      String :conversation_ref, size: 128
      String :request_ref, size: 128, null: false
      String :event_type, size: 64, null: false
      String :component, size: 64, null: false
      Integer :estimated_tokens_before, null: false, default: 0
      Integer :estimated_tokens_after, null: false, default: 0
      Integer :estimated_tokens_delta, null: false, default: 0
      Integer :message_count_before, null: false, default: 0
      Integer :message_count_after, null: false, default: 0
      String :metadata_json, text: true
      DateTime :recorded_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :message_inference_request_id
      index :message_inference_response_id
      index :message_inference_metric_id
      index :request_ref
      index :conversation_ref
      index %i[event_type component]
      index :recorded_at
    end
  end

  down do
    drop_table(:llm_context_accounting_events)

    alter_table(:llm_message_inference_metrics) do
      drop_column :context_accounting_json
      drop_column :context_accounting_status
      drop_column :tool_definition_count
      drop_column :rag_entry_count
      drop_column :context_window_message_count_after
      drop_column :context_window_message_count_before
      drop_column :stripped_thinking_message_count
      drop_column :archived_history_message_count
      drop_column :curated_history_message_count
      drop_column :loaded_history_message_count
      drop_column :final_context_estimated_tokens
      drop_column :tool_definition_estimated_tokens
      drop_column :baseline_system_estimated_tokens
      drop_column :system_prompt_estimated_tokens
      drop_column :rag_injected_estimated_tokens
      drop_column :context_window_saved_estimated_tokens
      drop_column :archive_saved_estimated_tokens
      drop_column :archived_history_estimated_tokens
      drop_column :stripped_thinking_estimated_tokens
      drop_column :curation_saved_estimated_tokens
      drop_column :curated_history_estimated_tokens
      drop_column :loaded_history_estimated_tokens
      drop_column :request_message_estimated_tokens
    end
  end
end
