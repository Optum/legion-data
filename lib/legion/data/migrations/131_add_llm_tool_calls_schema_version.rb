# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_tool_calls)

    existing = schema(:llm_tool_calls).map(&:first)
    next if existing.include?(:schema_version)

    alter_table(:llm_tool_calls) do
      add_column :schema_version, Integer, null: false, default: 15
    end
  end

  down do
    next unless table_exists?(:llm_tool_calls)

    alter_table(:llm_tool_calls) do
      drop_column :schema_version
    end
  end
end
