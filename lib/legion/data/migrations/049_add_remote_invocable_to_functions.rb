# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:functions)
    return if schema(:functions).any? { |c, _| c == :remote_invocable }

    alter_table(:functions) do
      add_column :remote_invocable, TrueClass, default: true, null: false
    end
  end

  down do
    return unless table_exists?(:functions)
    return unless schema(:functions).any? { |c, _| c == :remote_invocable }

    alter_table(:functions) do
      drop_column :remote_invocable
    end
  end
end
