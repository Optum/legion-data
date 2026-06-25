# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:digital_workers) do
      add_column :health_status, String, size: 20, default: 'unknown', null: false
      add_column :last_heartbeat_at, DateTime, null: true
      add_column :health_node, String, size: 255, null: true
      add_index  :health_status
    end

    alter_table(:nodes) do
      add_column :metrics,           :text, null: true
      add_column :hosted_worker_ids, :text, null: true
      add_column :version,           String, size: 50, null: true
    end
  end

  down do
    alter_table(:digital_workers) do
      drop_index  :health_status
      drop_column :health_node
      drop_column :last_heartbeat_at
      drop_column :health_status
    end

    alter_table(:nodes) do
      drop_column :version
      drop_column :hosted_worker_ids
      drop_column :metrics
    end
  end
end
