# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:functions)
    next if schema(:functions).any? { |c, _| c == :remote_invocable }

    alter_table(:functions) do
      add_column :remote_invocable, TrueClass, default: true, null: false
    end
  end

  down do
    next unless table_exists?(:functions)
    next unless schema(:functions).any? { |c, _| c == :remote_invocable }

    alter_table(:functions) do
      drop_column :remote_invocable
    end
  end
end
