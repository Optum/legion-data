# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_conversations) do
      add_column :pii_types_json, :text, null: true
      add_column :jurisdictions_json, :text, null: true
    end
  end

  down do
    alter_table(:llm_conversations) do
      drop_column :jurisdictions_json
      drop_column :pii_types_json
    end
  end
end
