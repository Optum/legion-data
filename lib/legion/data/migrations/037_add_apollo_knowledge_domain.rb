# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      add_column :knowledge_domain, String, size: 50, default: 'general'
    end

    add_index :apollo_entries, :knowledge_domain
  end

  down do
    next unless adapter_scheme == :postgres

    drop_index :apollo_entries, :knowledge_domain
    alter_table(:apollo_entries) do
      drop_column :knowledge_domain
    end
  end
end
