# frozen_string_literal: true

Sequel.migration do
  up do
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_access_scope ON apollo_entries (access_scope)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_identity_principal_id ON apollo_entries (identity_principal_id) WHERE identity_principal_id IS NOT NULL'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_identity_id ON apollo_entries (identity_id) WHERE identity_id IS NOT NULL'
  end

  down do
    run 'DROP INDEX IF EXISTS idx_apollo_access_scope'
    run 'DROP INDEX IF EXISTS idx_apollo_identity_principal_id'
    run 'DROP INDEX IF EXISTS idx_apollo_identity_id'
  end
end
