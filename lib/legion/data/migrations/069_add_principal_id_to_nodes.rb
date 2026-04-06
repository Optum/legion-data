# frozen_string_literal: true

Sequel.migration do
  up do
    return unless adapter_scheme == :postgres

    alter_table(:nodes) do
      add_column :principal_id, :uuid
      add_foreign_key [:principal_id], :principals
    end

    add_index :nodes, :principal_id
  end

  down do
    return unless adapter_scheme == :postgres

    alter_table(:nodes) do
      drop_column :principal_id
    end
  end
end
