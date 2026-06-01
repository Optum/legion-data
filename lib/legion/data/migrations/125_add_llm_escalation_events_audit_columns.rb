# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_escalation_events)

    alter_table(:llm_escalation_events) do
      add_column :history_json, :text, null: true
      add_column :outcome, String, size: 32, null: true
      add_column :total_attempts, Integer, null: true
      add_index :outcome, name: :idx_escalation_events_outcome
    end
  end

  down do
    next unless table_exists?(:llm_escalation_events)

    alter_table(:llm_escalation_events) do
      drop_index :outcome, name: :idx_escalation_events_outcome
      drop_column :total_attempts
      drop_column :outcome
      drop_column :history_json
    end
  end
end
