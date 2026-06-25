# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:relationships) do
      primary_key :id
      foreign_key :trigger_id, :functions, null: true, on_delete: :set_null, index: true
      foreign_key :action_id, :functions, null: true, on_delete: :set_null, index: true
      String :name, size: 255, null: true
      String :status, size: 50, null: false, default: 'active', index: true
      String :relationship_type, size: 50, null: false, default: 'chain'
      String :options, text: true, null: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end

  down do
    drop_table :relationships
  end
end
