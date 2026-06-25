# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_tool_call_attempts)

    existing = schema(:llm_tool_call_attempts).map(&:first)

    alter_table(:llm_tool_call_attempts) do
      add_column :attempt_input_json, :text, null: true unless existing.include?(:attempt_input_json)
      add_column :attempt_output_json, :text, null: true unless existing.include?(:attempt_output_json)
      add_column :error_details_json, :text, null: true unless existing.include?(:error_details_json)
    end
  end

  down do
    next unless table_exists?(:llm_tool_call_attempts)

    alter_table(:llm_tool_call_attempts) do
      drop_column :error_details_json
      drop_column :attempt_output_json
      drop_column :attempt_input_json
    end
  end
end
