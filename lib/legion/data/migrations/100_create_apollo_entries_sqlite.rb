# frozen_string_literal: true

Sequel.migration do
  up do
    next if adapter_scheme == :postgres

    create_table(:apollo_entries) do
      primary_key :id
      String :content, text: true, null: false
      String :content_type, null: false, size: 50
      Float :confidence, default: 0.5
      String :source_agent, null: false, size: 255
      String :source_context, text: true, default: '{}'
      String :tags, text: true, default: '{}'
      String :status, null: false, size: 20, default: 'candidate'
      Integer :access_count, default: 0
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :confirmed_at
      String :source_provider, size: 255
      String :source_channel, size: 100
      String :knowledge_domain, size: 255, default: 'general'
      String :submitted_by, size: 255
      String :submitted_from, size: 255
      String :content_hash, fixed: true, size: 64
      String :summary_l0, size: 500
      String :summary_l1, text: true
      String :knowledge_tier, null: false, size: 4, default: 'L2'
      String :parent_entry_id, size: 36
      DateTime :l0_generated_at
      DateTime :l1_generated_at
      String :parent_knowledge_id, size: 36
      TrueClass :is_latest, null: false, default: true
      String :supersession_type, size: 20
      DateTime :expires_at
      String :forget_reason, size: 255
      TrueClass :is_inference, null: false, default: false
    end

    create_table(:apollo_entries_archive) do
      primary_key :id
      String :content, text: true, null: false
      String :content_type, null: false, size: 50
      Float :confidence, default: 0.5
      String :source_agent, null: false, size: 255
      String :source_context, text: true, default: '{}'
      String :tags, text: true, default: '{}'
      String :status, null: false, size: 20, default: 'candidate'
      Integer :access_count, default: 0
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :confirmed_at
      String :source_provider, size: 255
      String :source_channel, size: 100
      String :knowledge_domain, size: 255, default: 'general'
      String :submitted_by, size: 255
      String :submitted_from, size: 255
      String :content_hash, fixed: true, size: 64
      String :summary_l0, size: 500
      String :summary_l1, text: true
      String :knowledge_tier, null: false, size: 4, default: 'L2'
      String :parent_entry_id, size: 36
      DateTime :l0_generated_at
      DateTime :l1_generated_at
      String :parent_knowledge_id, size: 36
      TrueClass :is_latest, null: false, default: true
      String :supersession_type, size: 20
      DateTime :expires_at
      String :forget_reason, size: 255
      TrueClass :is_inference, null: false, default: false
      DateTime :archived_at, default: Sequel::CURRENT_TIMESTAMP
      String :archive_reason, text: true
    end
  end

  down do
    next if adapter_scheme == :postgres

    drop_table(:apollo_entries_archive) if table_exists?(:apollo_entries_archive)
    drop_table(:apollo_entries) if table_exists?(:apollo_entries)
  end
end
