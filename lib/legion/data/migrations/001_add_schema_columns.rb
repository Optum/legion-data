require 'sequel/extensions/migration'

Sequel.migration do
  up do
    alter_table(:schema_info) do
      add_column :created_at, DateTime, default: Sequel::CURRENT_TIMESTAMP, null: false
      add_column :updated_at, DateTime, null: true
      add_column :catalog, String, size: 255, null: true
    end
  end

  down do
    alter_table(:schema_info) do
      drop_column :catalog
      drop_column :updated_at
      drop_column :created_at
    end
  end
end
