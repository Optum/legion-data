# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_tool_calls) do
      add_column :tool_arguments_json, Text, null: true
      add_column :tool_result_json, Text, null: true
      add_column :tool_category, String, size: 64, null: true
      add_column :data_handling_classification, String, size: 32, null: true
      add_column :policy_decision, String, size: 32, null: true
      add_column :requires_human_approval, TrueClass, null: true
      add_index :tool_category, name: :idx_tool_calls_tool_category
      add_index :data_handling_classification, name: :idx_tool_calls_data_handling_classification
      add_index :policy_decision, name: :idx_tool_calls_policy_decision
    end
  end
end
