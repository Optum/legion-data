# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:functions)
    next if schema(:functions).any? { |c, _| c == :component_type }

    alter_table(:functions) do
      add_column :component_type, String, size: 32, null: false, default: 'runner'
      add_index :component_type, name: :idx_functions_component_type, if_not_exists: true
    end
  end

  down do
    next unless table_exists?(:functions)
    next unless schema(:functions).any? { |c, _| c == :component_type }

    alter_table(:functions) do
      drop_index :component_type, name: :idx_functions_component_type, if_exists: true
      drop_column :component_type
    end
  end
end
