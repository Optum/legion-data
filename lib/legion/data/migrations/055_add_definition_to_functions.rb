# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:functions)
    next if schema(:functions).any? { |c, _| c == :definition }

    alter_table(:functions) do
      add_column :definition, String, text: true, null: true
    end
  end

  down do
    next unless table_exists?(:functions)
    next unless schema(:functions).any? { |c, _| c == :definition }

    alter_table(:functions) do
      drop_column :definition
    end
  end
end
