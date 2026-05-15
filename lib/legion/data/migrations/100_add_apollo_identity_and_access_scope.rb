# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      add_column :access_scope,            String, size: 20, null: false, default: 'global'
      add_column :identity_principal_id,   Integer, null: true
      add_column :identity_id,             Integer, null: true
      add_column :identity_canonical_name, String, size: 255, null: true
    end

    alter_table(:apollo_entries_archive) do
      add_column :access_scope,            String, size: 20,  null: false, default: 'global'
      add_column :identity_principal_id,   Integer, null: true
      add_column :identity_id,             Integer, null: true
      add_column :identity_canonical_name, String, size: 255, null: true
    end
  end

  down do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      drop_column :access_scope
      drop_column :identity_principal_id
      drop_column :identity_id
      drop_column :identity_canonical_name
    end

    alter_table(:apollo_entries_archive) do
      drop_column :access_scope
      drop_column :identity_principal_id
      drop_column :identity_id
      drop_column :identity_canonical_name
    end
  end
end
