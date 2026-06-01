# frozen_string_literal: true

# NOTE: request_content_hash, curation_strategy, and tool_policy already exist
# (migration 079) — all skipped. Only parent_request_id is new.

Sequel.migration do
  change do
    alter_table(:llm_message_inference_requests) do
      add_foreign_key :parent_request_id, :llm_message_inference_requests, null: true, on_delete: :set_null
    end
  end
end
