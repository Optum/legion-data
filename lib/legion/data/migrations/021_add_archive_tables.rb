# frozen_string_literal: true

Sequel.migration do
  up do
    unless table_exists?(:tasks_archive)
      create_table(:tasks_archive) do
        primary_key :id
        Integer :original_id, null: false
        String :function_name
        String :status
        String :runner_class
        column :args, :text
        column :result, :text
        String :queue
        Integer :relationship_id
        String :chain_id
        DateTime :original_created_at
        DateTime :original_updated_at
        DateTime :archived_at, null: false, default: Sequel::CURRENT_TIMESTAMP
        index :original_id
        index :chain_id
        index :archived_at
      end
    end

    unless table_exists?(:metering_records_archive)
      create_table(:metering_records_archive) do
        primary_key :id
        Integer :original_id, null: false
        String :worker_id
        String :event_type
        String :extension
        String :runner_function
        String :status
        Integer :tokens_in
        Integer :tokens_out
        Float :cost_usd
        Integer :wall_clock_ms
        Integer :cpu_time_ms
        Integer :external_api_calls
        String :model
        String :tenant_id
        DateTime :original_created_at
        DateTime :archived_at, null: false, default: Sequel::CURRENT_TIMESTAMP
        index :original_id
        index :worker_id
        index :tenant_id
        index :archived_at
      end
    end
  end

  down do
    drop_table(:metering_records_archive) if table_exists?(:metering_records_archive)
    drop_table(:tasks_archive) if table_exists?(:tasks_archive)
  end
end
