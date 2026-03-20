# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:agent_cluster_tasks)

    create_table(:agent_cluster_tasks) do
      primary_key :id
      String :task_type, null: false
      Text :payload
      String :assigned_to
      String :status, null: false, default: 'pending'
      DateTime :created_at, null: false
      DateTime :completed_at
      String :tenant_id
      index :status
      index :assigned_to
      index :tenant_id
    end
  end

  down do
    drop_table?(:agent_cluster_tasks)
  end
end
