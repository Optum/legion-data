# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:principals) do
      add_column :employee_id, String
    end
    run 'CREATE INDEX idx_principals_employee_id ON principals (employee_id) WHERE employee_id IS NOT NULL'

    alter_table(:identities) do
      add_column :account_type, String, null: false, default: 'primary'
      add_column :qualifier, String
      add_column :is_default, TrueClass, null: false, default: false
      add_column :link_evidence, String
    end

    run 'CREATE UNIQUE INDEX identities_one_default_per_provider ON identities (principal_id, provider_id) WHERE is_default = true AND active = true'
  end

  down do
    next unless adapter_scheme == :postgres

    run 'DROP INDEX IF EXISTS identities_one_default_per_provider'

    alter_table(:identities) do
      drop_column :link_evidence
      drop_column :is_default
      drop_column :qualifier
      drop_column :account_type
    end

    run 'DROP INDEX IF EXISTS idx_principals_employee_id'
    alter_table(:principals) do
      drop_column :employee_id
    end
  end
end
