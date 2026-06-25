# frozen_string_literal: true

Sequel.migration do
  up do
    # PostgreSQL only — these auto-named indexes from migration 012 are exact duplicates
    # of explicitly named indexes added in migration 047.
    next unless adapter_scheme == :postgres

    run 'DROP INDEX IF EXISTS apollo_entries_status_index'
    run 'DROP INDEX IF EXISTS apollo_relations_from_entry_id_index'
    run 'DROP INDEX IF EXISTS apollo_relations_to_entry_id_index'
    run 'DROP INDEX IF EXISTS apollo_expertise_agent_id_index'
    run 'DROP INDEX IF EXISTS apollo_expertise_domain_index'
  end

  down do
    next unless adapter_scheme == :postgres

    # Recreate the auto-named indexes that migration 012 created inline.
    # idx_apollo_status, idx_apollo_rel_from, etc. from migration 047 remain in place.
    run 'CREATE INDEX IF NOT EXISTS apollo_entries_status_index ON apollo_entries (status)' \
      if table_exists?(:apollo_entries)
    run 'CREATE INDEX IF NOT EXISTS apollo_relations_from_entry_id_index ON apollo_relations (from_entry_id)' \
      if table_exists?(:apollo_relations)
    run 'CREATE INDEX IF NOT EXISTS apollo_relations_to_entry_id_index ON apollo_relations (to_entry_id)' \
      if table_exists?(:apollo_relations)
    run 'CREATE INDEX IF NOT EXISTS apollo_expertise_agent_id_index ON apollo_expertise (agent_id)' \
      if table_exists?(:apollo_expertise)
    run 'CREATE INDEX IF NOT EXISTS apollo_expertise_domain_index ON apollo_expertise (domain)' \
      if table_exists?(:apollo_expertise)
  end
end
