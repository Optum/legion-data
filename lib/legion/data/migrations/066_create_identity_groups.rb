# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    create_table(:identity_groups) do
      column :id, :uuid, default: Sequel.lit('gen_random_uuid()'), primary_key: true
      String :name, null: false, unique: true
      String :source, null: false, default: 'ldap' # ldap, entra, manual
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    next unless adapter_scheme == :postgres

    drop_table?(:identity_groups)
  end
end
