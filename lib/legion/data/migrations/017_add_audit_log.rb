# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:audit_log) do
      primary_key :id
      String   :event_type,     null: false, size: 50
      String   :principal_id,   null: false, size: 255
      String   :principal_type, null: false, size: 20
      String   :action,         null: false, size: 100
      String   :resource,       null: false, size: 500
      String   :source,         null: false, size: 20
      String   :node,           null: false, size: 255
      String   :status,         null: false, size: 20
      Integer  :duration_ms,    null: true
      column   :detail,         :text, null: true
      String   :record_hash,    null: false, size: 64
      String   :prev_hash,      null: false, size: 64
      DateTime :created_at,     null: false

      index :event_type
      index :principal_id
      index :created_at
    end
  end

  down do
    drop_table :audit_log
  end
end
