# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_route_attempts) do
      add_column :operation, String, size: 64, null: true
      add_column :dispatch_path, String, size: 32, null: true
      add_column :idempotency_key, String, size: 128, null: true
      add_index :operation, name: :idx_route_attempts_operation
      add_index :idempotency_key, name: :idx_route_attempts_idempotency_key
    end
  end

  down do
    alter_table(:llm_route_attempts) do
      drop_index :operation, name: :idx_route_attempts_operation
      drop_index :idempotency_key, name: :idx_route_attempts_idempotency_key
      drop_column :operation
      drop_column :dispatch_path
      drop_column :idempotency_key
    end
  end
end
