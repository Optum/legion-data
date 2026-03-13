# frozen_string_literal: true

require 'sequel/extensions/migration'

Sequel.migration do
  up do
    alter_table(:schema_info) do
      # SQLite does not support non-constant defaults in ALTER TABLE ADD COLUMN,
      # so we omit the default here and let the application set timestamps.
      add_column :created_at, DateTime, null: true
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
