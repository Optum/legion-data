# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_escalation_events) do
      add_column :history_json, Text, null: true
      add_column :outcome, String, size: 32, null: true
      add_column :total_attempts, Integer, null: true
      add_index :outcome, name: :idx_escalation_events_outcome
    end
  end
end
