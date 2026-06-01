# frozen_string_literal: true

Sequel.migration do
  up do
    %i[apollo_access_log memory_traces memory_associations audit_log audit_records].each do |table|
      next unless table_exists?(table)

      cols = schema(table).map(&:first)
      alter_table(table) do
        add_column :identity_principal_id, Integer, null: true unless cols.include?(:identity_principal_id)
        add_column :identity_id, Integer, null: true unless cols.include?(:identity_id)
        add_column :identity_canonical_name, String, size: 255, null: true unless cols.include?(:identity_canonical_name)
      end
    end
  end

  down do
    %i[apollo_access_log memory_traces memory_associations audit_log audit_records].each do |table|
      next unless table_exists?(table)

      cols = schema(table).map(&:first)
      alter_table(table) do
        drop_column :identity_canonical_name if cols.include?(:identity_canonical_name)
        drop_column :identity_id if cols.include?(:identity_id)
        drop_column :identity_principal_id if cols.include?(:identity_principal_id)
      end
    end
  end
end
