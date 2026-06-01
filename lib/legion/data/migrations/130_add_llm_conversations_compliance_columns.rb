# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_conversations) do
      add_column :pii_types_json, :text, null: true
      add_column :jurisdictions_json, :text, null: true
      add_column :schema_version, Integer, null: false, default: 15
    end
  end

  down do
    alter_table(:llm_conversations) do
      drop_column :schema_version
      drop_column :jurisdictions_json
      drop_column :pii_types_json
    end
  end
end
