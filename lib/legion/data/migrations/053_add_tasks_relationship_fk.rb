# frozen_string_literal: true

Sequel.migration do
  up do
    # PostgreSQL only — add FK constraint for tasks.relationship_id with ON DELETE SET NULL.
    # Orphaned values must be cleaned first.
    next unless adapter_scheme == :postgres
    next unless table_exists?(:tasks)
    next unless table_exists?(:relationships)

    # Clean orphaned relationship_id values before adding constraint
    run <<~SQL
      UPDATE tasks
      SET relationship_id = NULL
      WHERE relationship_id IS NOT NULL
        AND relationship_id NOT IN (SELECT id FROM relationships);
    SQL

    run <<~SQL
      ALTER TABLE tasks
        ADD CONSTRAINT fk_tasks_relationship_id
        FOREIGN KEY (relationship_id) REFERENCES relationships(id)
        ON DELETE SET NULL;
    SQL
  end

  down do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:tasks)

    run 'ALTER TABLE tasks DROP CONSTRAINT IF EXISTS fk_tasks_relationship_id'
  end
end
