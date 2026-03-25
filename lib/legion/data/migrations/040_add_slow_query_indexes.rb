# frozen_string_literal: true

Sequel.migration do
  up do
    # tasks.created — used by tasker check_subtask time-range scans
    next unless table_exists?(:tasks)

    alter_table(:tasks) do
      add_index :created, name: :idx_tasks_created, if_not_exists: true
      add_index %i[status function_id relationship_id], name: :idx_tasks_status_func_rel, if_not_exists: true
    end
  end

  down do
    next unless table_exists?(:tasks)

    alter_table(:tasks) do
      drop_index :created, name: :idx_tasks_created, if_exists: true
      drop_index %i[status function_id relationship_id], name: :idx_tasks_status_func_rel, if_exists: true
    end
  end
end
