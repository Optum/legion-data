# frozen_string_literal: true

Sequel.migration do
  up do
    existing = schema(:llm_tool_calls).map(&:first)
    next unless existing.include?(:schema_version)

    alter_table(:llm_tool_calls) do
      drop_column :schema_version
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      add_column :schema_version, Integer, null: false, default: 15
    end
  end
end
