# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:approval_queue)

    create_table(:approval_queue) do
      primary_key :id
      String :approval_type, null: false
      Text :payload
      String :requester_id, null: false
      String :status, null: false, default: 'pending'
      String :reviewer_id
      DateTime :reviewed_at
      DateTime :created_at, null: false
      String :tenant_id
      index :status
      index :tenant_id
      index :created_at
    end
  end

  down do
    drop_table?(:approval_queue)
  end
end
