# frozen_string_literal: true

# The Great Convergence (part 2): create apollo_relations, apollo_expertise,
# apollo_access_log, and apollo_operations on all adapters.
#
# Migration 012 (postgres-only) created apollo_relations, apollo_expertise,
# and apollo_access_log.
# Migration 047 (postgres-only) created apollo_operations.
# These tables were never created on SQLite/MySQL deployments.

Sequel.migration do
  up do
    # apollo_relations
    unless table_exists?(:apollo_relations)
      create_table(:apollo_relations) do
        primary_key :id
        String :from_entry_id, size: 36, null: false
        String :to_entry_id, size: 36, null: false
        String :relation_type, null: false, size: 50
        Float :weight, default: 1.0
        String :source_agent, size: 255
        DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

        index :from_entry_id, name: :idx_apollo_rel_from
        index :to_entry_id, name: :idx_apollo_rel_to
        index :relation_type, name: :idx_apollo_rel_type
        index %i[from_entry_id relation_type], name: :idx_apollo_rel_composite
      end
    end

    # apollo_expertise
    unless table_exists?(:apollo_expertise)
      create_table(:apollo_expertise) do
        primary_key :id
        String :agent_id, null: false, size: 255, index: { name: :idx_apollo_exp_agent }
        String :domain, null: false, size: 255, index: { name: :idx_apollo_exp_domain }
        Float :proficiency, default: 0.0
        Integer :entry_count, default: 0
        DateTime :last_active_at, default: Sequel::CURRENT_TIMESTAMP

        index %i[agent_id domain], name: :idx_apollo_exp_composite
      end
    end

    # apollo_access_log
    unless table_exists?(:apollo_access_log)
      create_table(:apollo_access_log) do
        primary_key :id
        String :entry_id, size: 36, index: { name: :idx_apollo_access_entry }
        String :agent_id, null: false, size: 255
        String :action, null: false, size: 20
        DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      end
    end

    # apollo_operations
    unless table_exists?(:apollo_operations)
      create_table(:apollo_operations) do
        primary_key :id
        String :operation, size: 50, null: false
        String :actor, size: 255, null: false
        String :target_type, size: 50
        String :target_ids, text: true # serialized array; PG uses INTEGER[]
        String :summary, text: true
        String :detail, text: true, default: '{}' # serialized json; PG uses JSONB
        String :old_state, text: true
        String :new_state, text: true
        String :reason, text: true
        String :principal_id, size: 255
        DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

        index :created_at, name: :idx_apollo_ops_created
        index :operation, name: :idx_apollo_ops_operation
        index :actor, name: :idx_apollo_ops_actor
      end
    end
  end

  down do
    drop_table :apollo_operations if table_exists?(:apollo_operations)
    drop_table :apollo_access_log if table_exists?(:apollo_access_log)
    drop_table :apollo_expertise if table_exists?(:apollo_expertise)
    drop_table :apollo_relations if table_exists?(:apollo_relations)
  end
end
