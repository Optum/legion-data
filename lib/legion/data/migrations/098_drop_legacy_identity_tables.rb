# frozen_string_literal: true

Sequel.migration do
  up do
    drop_table(:identity_audit_log) if table_exists?(:identity_audit_log)
    drop_table(:identity_group_memberships) if table_exists?(:identity_group_memberships)
    drop_table(:identity_groups) if table_exists?(:identity_groups)
    drop_table(:identities) if table_exists?(:identities)

    alter_table(:nodes) { drop_column :principal_id } if table_exists?(:nodes) && schema(:nodes).any? { |col, _| col == :principal_id }

    drop_table(:principals) if table_exists?(:principals)
    drop_table(:identity_providers) if table_exists?(:identity_providers)
  end

  down do
    nil
  end
end
