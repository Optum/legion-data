# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_tool_call_attempts) do
      add_column :attempt_input_json, :text, null: true
      add_column :attempt_output_json, :text, null: true
      add_column :error_details_json, :text, null: true
    end
  end
end
