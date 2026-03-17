# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:governance_events) do
      primary_key :id
      String :stream_id, null: false
      String :event_type, null: false
      Integer :sequence_number, null: false
      column :data_json, :text
      column :metadata_json, :text
      String :event_hash, size: 64
      String :previous_hash, size: 64
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index %i[stream_id sequence_number], unique: true
      index :event_type
      index :created_at
    end
  end
end
