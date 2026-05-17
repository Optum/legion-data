# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_registry_events) do
      add_column :access_scope, String, size: 20, null: false, default: 'global'
      add_column :identity_principal_id, Integer, null: true
      add_column :identity_id, Integer, null: true
      add_column :identity_canonical_name, String, size: 255, null: true
      add_index :access_scope, name: :idx_registry_events_access_scope
      add_index :identity_principal_id, name:  :idx_registry_events_identity_principal_id,
                                        where: Sequel.negate(identity_principal_id: nil)
    end
  end

  down do
    alter_table(:llm_registry_events) do
      drop_index :identity_principal_id, name: :idx_registry_events_identity_principal_id
      drop_index :access_scope, name: :idx_registry_events_access_scope
      drop_column :access_scope
      drop_column :identity_principal_id
      drop_column :identity_id
      drop_column :identity_canonical_name
    end
  end
end
