# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:tasks)
    next if schema(:tasks).any? { |col, _| col == :task_delay }

    alter_table(:tasks) do
      add_column :task_delay, Integer, null: true
    end
  end

  down do
    next unless table_exists?(:tasks)
    next unless schema(:tasks).any? { |col, _| col == :task_delay }

    alter_table(:tasks) do
      drop_column :task_delay
    end
  end
end
