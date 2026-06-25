# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:tasks)
    next if schema(:tasks).any? { |col, _| col == :cancelled_at }

    alter_table(:tasks) do
      add_column :cancelled_at, DateTime, null: true
    end
  end

  down do
    next unless table_exists?(:tasks)
    next unless schema(:tasks).any? { |col, _| col == :cancelled_at }

    alter_table(:tasks) do
      drop_column :cancelled_at
    end
  end
end
