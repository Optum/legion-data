# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    run 'CREATE INDEX idx_apollo_access_scope ON apollo_entries (access_scope)'
    run 'CREATE INDEX idx_apollo_identity_principal_id ON apollo_entries (identity_principal_id) WHERE identity_principal_id IS NOT NULL'
    run 'CREATE INDEX idx_apollo_identity_id ON apollo_entries (identity_id) WHERE identity_id IS NOT NULL'
  end

  down do
    next unless adapter_scheme == :postgres

    run 'DROP INDEX IF EXISTS idx_apollo_access_scope'
    run 'DROP INDEX IF EXISTS idx_apollo_identity_principal_id'
    run 'DROP INDEX IF EXISTS idx_apollo_identity_id'
  end
end
