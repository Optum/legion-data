# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:tenants) do
      primary_key :id
      String :tenant_id, null: false, unique: true, size: 100
      String :name, size: 255
      String :status, default: 'active', size: 20
      Integer :max_workers, default: 10
      Integer :max_queue_depth, default: 10_000
      Float :monthly_token_limit
      Float :daily_token_limit
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
      index :status
    end
  end

  down do
    drop_table?(:tenants)
  end
end
