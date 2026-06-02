# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_message_inference_responses)

    existing = schema(:llm_message_inference_responses).map(&:first)

    alter_table(:llm_message_inference_responses) do
      add_column :route_attempts, Integer, null: true, default: 0 unless existing.include?(:route_attempts)
      add_column :escalation_chain_ref, String, size: 128, null: true unless existing.include?(:escalation_chain_ref)
    end

    add_index :llm_message_inference_responses, :escalation_chain_ref,
              name: :idx_inference_responses_escalation_chain_ref, if_not_exists: true
  end

  down do
    next unless table_exists?(:llm_message_inference_responses)

    alter_table(:llm_message_inference_responses) do
      drop_column :escalation_chain_ref
      drop_column :route_attempts
    end
  end
end
