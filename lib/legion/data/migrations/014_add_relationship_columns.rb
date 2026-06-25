# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:relationships) do
      add_column :delay, Integer, null: false, default: 0
      add_column :chain_id, Integer, null: true, index: true
      add_column :debug, TrueClass, null: false, default: false
      add_column :allow_new_chains, TrueClass, null: false, default: false
      add_column :conditions, String, text: true, null: true
      add_column :transformation, String, text: true, null: true
      add_column :active, TrueClass, null: false, default: true, index: true
    end
  end

  down do
    alter_table(:relationships) do
      drop_column :delay
      drop_column :chain_id
      drop_column :debug
      drop_column :allow_new_chains
      drop_column :conditions
      drop_column :transformation
      drop_column :active
    end
  end
end
