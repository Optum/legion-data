# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_tool_calls)

    existing = schema(:llm_tool_calls).map(&:first)

    alter_table(:llm_tool_calls) do
      add_column :tool_arguments_json, :text, null: true unless existing.include?(:tool_arguments_json)
      add_column :tool_result_json, :text, null: true unless existing.include?(:tool_result_json)
      add_column :tool_category, String, size: 64, null: true unless existing.include?(:tool_category)
      add_column :data_handling_classification, String, size: 32, null: true unless existing.include?(:data_handling_classification)
      add_column :policy_decision, String, size: 32, null: true unless existing.include?(:policy_decision)
      add_column :requires_human_approval, TrueClass, null: true unless existing.include?(:requires_human_approval)
    end

    add_index :llm_tool_calls, :tool_category, name: :idx_tool_calls_tool_category, if_not_exists: true
    add_index :llm_tool_calls, :data_handling_classification, name: :idx_tool_calls_data_handling_classification, if_not_exists: true
    add_index :llm_tool_calls, :policy_decision, name: :idx_tool_calls_policy_decision, if_not_exists: true
  end

  down do
    next unless table_exists?(:llm_tool_calls)

    alter_table(:llm_tool_calls) do
      drop_column :requires_human_approval
      drop_column :policy_decision
      drop_column :data_handling_classification
      drop_column :tool_category
      drop_column :tool_result_json
      drop_column :tool_arguments_json
    end
  end
end
