# frozen_string_literal: true

Sequel.migration do
  up do
    rename_table(:portable_identity_provider_capabilities, :identity_provider_capabilities)
    rename_table(:portable_identity_audit_log, :identity_audit_log)
    rename_table(:portable_identity_group_memberships, :identity_group_memberships)
    rename_table(:portable_identity_groups, :identity_groups)
    rename_table(:portable_identities, :identities)
    rename_table(:portable_identity_principals, :identity_principals)
    rename_table(:portable_identity_providers, :identity_providers)
  end

  down do
    rename_table(:identity_providers, :portable_identity_providers)
    rename_table(:identity_principals, :portable_identity_principals)
    rename_table(:identities, :portable_identities)
    rename_table(:identity_groups, :portable_identity_groups)
    rename_table(:identity_group_memberships, :portable_identity_group_memberships)
    rename_table(:identity_audit_log, :portable_identity_audit_log)
    rename_table(:identity_provider_capabilities, :portable_identity_provider_capabilities)
  end
end
