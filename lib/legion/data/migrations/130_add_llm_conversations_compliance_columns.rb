# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_conversations)

    existing = schema(:llm_conversations).map(&:first)

    alter_table(:llm_conversations) do
      add_column :pii_types_json, :text, null: true unless existing.include?(:pii_types_json)
      add_column :jurisdictions_json, :text, null: true unless existing.include?(:jurisdictions_json)
    end
  end

  down do
    next unless table_exists?(:llm_conversations)

    alter_table(:llm_conversations) do
      drop_column :jurisdictions_json
      drop_column :pii_types_json
    end
  end
end
