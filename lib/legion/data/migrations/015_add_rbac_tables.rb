# frozen_string_literal: true

Sequel.migration do
  up do
    create_table?(:rbac_role_assignments) do
      primary_key :id
      String :principal_type, null: false, size: 10
      String :principal_id,   null: false, size: 255
      String :role,           null: false, size: 100
      String :team,           null: true,  size: 255
      String :granted_by,     null: false, size: 255
      DateTime :granted_at,   null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :expires_at,   null: true
      unique %i[principal_type principal_id role team]
      index :principal_id
      index :team
    end

    create_table?(:rbac_runner_grants) do
      primary_key :id
      String :team,            null: false, size: 255
      String :runner_pattern,  null: false, size: 500
      String :actions,         null: false, size: 255
      String :granted_by,      null: false, size: 255
      DateTime :granted_at,    null: false, default: Sequel::CURRENT_TIMESTAMP
      unique %i[team runner_pattern]
      index :team
    end

    create_table?(:rbac_cross_team_grants) do
      primary_key :id
      String :source_team,     null: false, size: 255
      String :target_team,     null: false, size: 255
      String :runner_pattern,  null: false, size: 500
      String :actions,         null: false, size: 255
      String :granted_by,      null: false, size: 255
      DateTime :granted_at,    null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :expires_at,    null: true
      unique %i[source_team target_team runner_pattern]
      index :source_team
    end
  end

  down do
    drop_table :rbac_cross_team_grants
    drop_table :rbac_runner_grants
    drop_table :rbac_role_assignments
  end
end
