# frozen_string_literal: true

Sequel.migration do
  up do
    return unless adapter_scheme == :postgres

    create_table(:principals) do
      column :id, :uuid, default: Sequel.lit("gen_random_uuid()"), primary_key: true
      String :canonical_name, null: false
      String :kind, null: false  # human, service, machine
      String :display_name
      TrueClass :active, null: false, default: true
      DateTime :last_seen_at
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      constraint(:canonical_name_format, Sequel.lit("canonical_name ~ '^[a-z0-9][a-z0-9_-]*$'"))
      unique [:canonical_name, :kind]
    end

    add_index :principals, :canonical_name
    add_index :principals, :kind
  end

  down do
    return unless adapter_scheme == :postgres

    drop_table?(:principals)
  end
end
