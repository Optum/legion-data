# frozen_string_literal: true

Sequel.migration do
  up do
    create_table?(:extract_step_timings) do
      primary_key :id
      String :extract_id, size: 36, null: false
      String :name, size: 100, null: false
      DateTime :start_time, null: false
      DateTime :end_time, null: false
      String :status, size: 20, null: false
      String :error, text: true
      Integer :duration_ms, null: false, default: 0

      index :extract_id, name: :idx_extract_step_timings_extract_id
      index %i[extract_id name], name: :idx_extract_step_timings_extract_name
      index :status, name: :idx_extract_step_timings_status
    end
  end

  down do
    drop_table?(:extract_step_timings)
  end
end
