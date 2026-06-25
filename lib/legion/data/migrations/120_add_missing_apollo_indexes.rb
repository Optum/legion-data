# frozen_string_literal: true

# The Great Convergence (part 3): add missing indexes on apollo_* tables.
#
# Migration 047 (postgres-only) created dozens of indexes on apollo_entries,
# apollo_relations, apollo_expertise, apollo_operations, and
# apollo_entries_archive. These were never created on SQLite/MySQL.
#
# Vector indexes (hnsw) and GIN indexes are postgres-specific and skipped.
#
# NOTE: Uses raw CREATE INDEX IF NOT EXISTS SQL because Sequel's add_index
# inside alter_table does not honor if_not_exists on SQLite (it triggers
# table recreation which fails if the index already exists).

Sequel.migration do
  up do
    next unless table_exists?(:apollo_entries)

    run 'CREATE INDEX IF NOT EXISTS idx_apollo_submitted_by ON apollo_entries (submitted_by)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_submitted_from ON apollo_entries (submitted_from)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_status ON apollo_entries (status)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_confidence ON apollo_entries (confidence)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_created ON apollo_entries (created_at)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_updated ON apollo_entries (updated_at)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_domain ON apollo_entries (knowledge_domain)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_source_agent ON apollo_entries (source_agent)'
    run "CREATE UNIQUE INDEX IF NOT EXISTS idx_apollo_content_hash ON apollo_entries (content_hash) WHERE status != 'archived'"
    run "CREATE INDEX IF NOT EXISTS idx_apollo_active ON apollo_entries (id) WHERE status IN ('candidate', 'confirmed', 'disputed')"
    run "CREATE INDEX IF NOT EXISTS idx_apollo_decay_target ON apollo_entries (updated_at) WHERE status != 'archived'"
    run "CREATE INDEX IF NOT EXISTS idx_apollo_candidates ON apollo_entries (status, source_provider, source_channel) WHERE status = 'candidate'"

    next unless table_exists?(:apollo_entries_archive)

    run 'CREATE INDEX IF NOT EXISTS idx_archive_content_hash ON apollo_entries_archive (content_hash)'
    run 'CREATE INDEX IF NOT EXISTS idx_archive_source_agent ON apollo_entries_archive (source_agent)'
    run 'CREATE INDEX IF NOT EXISTS idx_archive_archived_at ON apollo_entries_archive (archived_at)'

    next unless table_exists?(:apollo_relations)

    run 'CREATE INDEX IF NOT EXISTS idx_apollo_rel_from ON apollo_relations (from_entry_id)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_rel_to ON apollo_relations (to_entry_id)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_rel_type ON apollo_relations (relation_type)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_rel_composite ON apollo_relations (from_entry_id, relation_type)'

    next unless table_exists?(:apollo_expertise)

    run 'CREATE INDEX IF NOT EXISTS idx_apollo_exp_agent ON apollo_expertise (agent_id)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_exp_domain ON apollo_expertise (domain)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_exp_composite ON apollo_expertise (agent_id, domain)'

    next unless table_exists?(:apollo_operations)

    run 'CREATE INDEX IF NOT EXISTS idx_apollo_ops_created ON apollo_operations (created_at)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_ops_operation ON apollo_operations (operation)'
    run 'CREATE INDEX IF NOT EXISTS idx_apollo_ops_actor ON apollo_operations (actor)'
  end

  down do
    %w[
      idx_apollo_submitted_by idx_apollo_submitted_from idx_apollo_status
      idx_apollo_confidence idx_apollo_created idx_apollo_updated
      idx_apollo_domain idx_apollo_source_agent idx_apollo_content_hash
      idx_apollo_active idx_apollo_decay_target idx_apollo_candidates
      idx_archive_content_hash idx_archive_source_agent idx_archive_archived_at
      idx_apollo_rel_from idx_apollo_rel_to idx_apollo_rel_type
      idx_apollo_rel_composite
      idx_apollo_exp_agent idx_apollo_exp_domain idx_apollo_exp_composite
      idx_apollo_ops_created idx_apollo_ops_operation idx_apollo_ops_actor
    ].each do |name|
      run "DROP INDEX IF EXISTS #{name}"
    end
  end
end
