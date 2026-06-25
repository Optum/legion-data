# frozen_string_literal: true

Sequel.migration do
  up do
    %i[extensions functions runners nodes settings value_metrics].each do |table|
      next unless table_exists?(table)
      next if schema(table).any? { |col, _| col == :tenant_id }

      alter_table(table) do
        add_column :tenant_id, String, size: 64
        add_index :tenant_id, name: :"idx_#{table}_tenant_id"
      end
    end
  end

  down do
    %i[extensions functions runners nodes settings value_metrics].each do |table|
      next unless table_exists?(table)
      next unless schema(table).any? { |col, _| col == :tenant_id }

      alter_table(table) do
        drop_index :tenant_id, name: :"idx_#{table}_tenant_id"
        drop_column :tenant_id
      end
    end
  end
end
