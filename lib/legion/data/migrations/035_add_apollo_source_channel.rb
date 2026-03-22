# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      add_column :source_channel, String, size: 100, null: true
    end
  end

  down do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      drop_column :source_channel
    end
  end
end
