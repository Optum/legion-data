# frozen_string_literal: true

Sequel.migration do
  up do
    return if table_exists?(:metering_hourly_rollup)

    create_table(:metering_hourly_rollup) do
      primary_key :id
      String :worker_id, size: 36, null: false
      String :provider, size: 100, null: false
      String :model_id, size: 255, null: false
      DateTime :hour, null: false
      Integer :total_input_tokens, default: 0, null: false
      Integer :total_output_tokens, default: 0, null: false
      Integer :total_thinking_tokens, default: 0, null: false
      Integer :total_calls, default: 0, null: false
      Float :total_cost_usd, default: 0.0, null: false
      Float :avg_latency_ms, default: 0.0, null: false
      String :tenant_id, size: 64
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      unique %i[worker_id provider model_id hour], name: :idx_rollup_unique_hour
      index :hour
      index :tenant_id
      index %i[worker_id hour]
    end
  end

  down do
    drop_table?(:metering_hourly_rollup)
  end
end
