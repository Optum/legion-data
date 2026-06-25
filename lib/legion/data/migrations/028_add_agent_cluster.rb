# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:agent_cluster_nodes)

    create_table(:agent_cluster_nodes) do
      primary_key :id
      String :node_id, null: false, unique: true
      String :role, null: false, default: 'worker'
      String :status, null: false, default: 'active'
      DateTime :joined_at, null: false
      DateTime :last_seen
      String :tenant_id
      index :status
      index :tenant_id
    end
  end

  down do
    drop_table?(:agent_cluster_nodes)
  end
end
