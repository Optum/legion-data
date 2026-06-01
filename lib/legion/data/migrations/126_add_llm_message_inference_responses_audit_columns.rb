# frozen_string_literal: true

# NOTE: response_content_hash already exists (migration 080) — skipped.

Sequel.migration do
  change do
    alter_table(:llm_message_inference_responses) do
      add_column :route_attempts, Integer, null: true, default: 0
      add_column :escalation_chain_ref, String, size: 128, null: true
      add_index :escalation_chain_ref, name: :idx_inference_responses_escalation_chain_ref
    end
  end
end
