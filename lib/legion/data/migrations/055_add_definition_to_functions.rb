# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:functions)
    return if schema(:functions).any? { |c, _| c == :definition }

    alter_table(:functions) do
      add_column :definition, String, text: true, null: true
    end
  end

  down do
    return unless table_exists?(:functions)
    return unless schema(:functions).any? { |c, _| c == :definition }

    alter_table(:functions) do
      drop_column :definition
    end
  end
end
