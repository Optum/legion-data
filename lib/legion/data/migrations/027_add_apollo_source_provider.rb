# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      add_column :source_provider, String, size: 50, null: true
    end

    run "UPDATE apollo_entries SET source_provider = 'unknown' WHERE source_provider IS NULL"
  end

  down do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      drop_column :source_provider
    end
  end
end
