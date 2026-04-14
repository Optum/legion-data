# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:relationships) do
      add_column :engine, String, size: 50, null: true
    end
  end

  down do
    alter_table(:relationships) do
      drop_column :engine
    end
  end
end
