# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:value_metrics) do
      primary_key :id
      String :worker_id,   null: false, size: 36, index: true
      String :metric_name, null: false, size: 255, index: true
      String :metric_type, null: false, size: 50
      Float  :value,       null: false, default: 0.0
      String :metadata,    text: true, null: true
      DateTime :recorded_at, null: false, default: Sequel::CURRENT_TIMESTAMP, index: true
    end
  end

  down do
    drop_table :value_metrics
  end
end
