# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:runners) do
      primary_key :id
      foreign_key :extension_id, :extensions, null: false, on_delete: :cascade, on_update: :cascade
      String :name, size: 256, null: false, default: ''
      String :namespace, size: 256, null: false, default: ''
      TrueClass :active, null: false, default: true
      String :queue, size: 256, null: true
      String :uri, size: 256, null: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end

  down do
    drop_table :runners
  end
end
