# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:tasks)

    existing_cols = schema(:tasks).map(&:first)
    next if existing_cols.include?(:created_at)

    if adapter_scheme == :postgres
      # Add a generated column so retention/archival queries using created_at work transparently
      run 'ALTER TABLE tasks ADD COLUMN created_at TIMESTAMPTZ GENERATED ALWAYS AS (created) STORED'
      run 'CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks (created_at)'
    else
      # SQLite/MySQL: add real column and backfill from created
      alter_table(:tasks) do
        add_column :created_at, DateTime
      end

      run 'UPDATE tasks SET created_at = created WHERE created_at IS NULL'

      alter_table(:tasks) do
        add_index :created_at, name: :idx_tasks_created_at, if_not_exists: true
      end
    end
  end

  down do
    next unless table_exists?(:tasks)

    existing_cols = schema(:tasks).map(&:first)
    next unless existing_cols.include?(:created_at)

    if adapter_scheme == :postgres
      run 'DROP INDEX IF EXISTS idx_tasks_created_at'
      run 'ALTER TABLE tasks DROP COLUMN IF EXISTS created_at'
    else
      alter_table(:tasks) do
        drop_index :created_at, name: :idx_tasks_created_at, if_exists: true
        drop_column :created_at
      end
    end
  end
end
