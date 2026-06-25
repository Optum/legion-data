# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:tasks)

    existing_columns = schema(:tasks).map(&:first)
    alter_table(:tasks) do
      add_column :idempotency_key, String, size: 64 unless existing_columns.include?(:idempotency_key)
      add_column :idempotency_expires_at, DateTime unless existing_columns.include?(:idempotency_expires_at)
    end

    add_index :tasks, :idempotency_key, name: :idx_tasks_idempotency_key, if_not_exists: true
    add_index :tasks, :idempotency_expires_at, name: :idx_tasks_idempotency_expires_at, if_not_exists: true
  end

  down do
    next unless table_exists?(:tasks)

    existing_columns = schema(:tasks).map(&:first)
    alter_table(:tasks) do
      drop_index :idempotency_key, name: :idx_tasks_idempotency_key, if_exists: true
      drop_index :idempotency_expires_at, name: :idx_tasks_idempotency_expires_at, if_exists: true
      drop_column :idempotency_expires_at if existing_columns.include?(:idempotency_expires_at)
      drop_column :idempotency_key if existing_columns.include?(:idempotency_key)
    end
  end
end
