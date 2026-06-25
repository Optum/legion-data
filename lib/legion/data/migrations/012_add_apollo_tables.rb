# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    run 'CREATE EXTENSION IF NOT EXISTS vector'
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

    create_table(:apollo_entries) do
      column :id, :uuid, default: Sequel.lit('uuid_generate_v4()'), primary_key: true
      String :content, text: true, null: false
      String :content_type, null: false, size: 50
      Float :confidence, default: 0.5
      String :source_agent, null: false, size: 100
      column :source_context, :jsonb, default: Sequel.lit("'{}'::jsonb")
      column :tags, :'text[]', default: Sequel.lit("'{}'::text[]")
      String :status, null: false, size: 20, default: 'candidate'
      Integer :access_count, default: 0
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :confirmed_at

      index :status
    end
    run 'ALTER TABLE apollo_entries ADD COLUMN embedding vector(1536)'
    run 'CREATE INDEX idx_apollo_entries_embedding ON apollo_entries USING hnsw (embedding vector_cosine_ops)'
    run 'CREATE INDEX idx_apollo_entries_tags ON apollo_entries USING gin (tags)'

    create_table(:apollo_relations) do
      column :id, :uuid, default: Sequel.lit('uuid_generate_v4()'), primary_key: true
      foreign_key :from_entry_id, :apollo_entries, type: :uuid, null: false, index: true
      foreign_key :to_entry_id, :apollo_entries, type: :uuid, null: false, index: true
      String :relation_type, null: false, size: 50
      Float :weight, default: 1.0
      String :source_agent, size: 100
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:apollo_expertise) do
      column :id, :uuid, default: Sequel.lit('uuid_generate_v4()'), primary_key: true
      String :agent_id, null: false, size: 100, index: true
      String :domain, null: false, size: 100, index: true
      Float :proficiency, default: 0.0
      Integer :entry_count, default: 0
      DateTime :last_active_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:apollo_access_log) do
      column :id, :uuid, default: Sequel.lit('uuid_generate_v4()'), primary_key: true
      foreign_key :entry_id, :apollo_entries, type: :uuid, index: true
      String :agent_id, null: false, size: 100
      String :action, null: false, size: 20
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    next unless adapter_scheme == :postgres

    drop_table(:apollo_access_log) if table_exists?(:apollo_access_log)
    drop_table(:apollo_expertise) if table_exists?(:apollo_expertise)
    drop_table(:apollo_relations) if table_exists?(:apollo_relations)
    drop_table(:apollo_entries) if table_exists?(:apollo_entries)
  end
end
