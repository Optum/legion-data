# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:digital_workers) do
      primary_key :id
      String :worker_id,      null: false, unique: true, size: 36
      String :name,           null: false, size: 255
      String :entra_app_id,   null: false, unique: true, size: 255
      String :entra_object_id, null: true, size: 255
      String :owner_msid,     null: false, size: 255
      String :owner_name,     null: true,  size: 255
      String :extension_name, null: false, size: 255
      String :business_role,  null: true,  size: 255
      String :risk_tier,      null: true,  size: 50
      String :lifecycle_state, null: false, default: 'bootstrap', size: 50
      String :consent_tier,   null: false, default: 'supervised', size: 50
      Float  :trust_score,    null: false, default: 0.0
      String :team,           null: true,  size: 255
      String :manager_msid,   null: true,  size: 255
      DateTime :created_at,   null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at,   null: true
      DateTime :retired_at,   null: true
      String :retired_by,     null: true,  size: 255
      String :retired_reason, null: true,  text: true
      index :owner_msid
      index :lifecycle_state
      index :team
    end

    alter_table(:tasks) do
      add_column :worker_id, String, null: true, size: 36
      add_index  :worker_id
    end
  end

  down do
    alter_table(:tasks) do
      drop_index  :worker_id
      drop_column :worker_id
    end

    drop_table :digital_workers
  end
end
