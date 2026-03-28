# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:runners)
    return if schema(:runners).any? { |c, _| c == :routing_key }

    alter_table(:runners) do
      add_column :routing_key, String, size: 512, null: true
      add_index :routing_key, name: :idx_runners_routing_key, if_not_exists: true
    end
  end

  down do
    return unless table_exists?(:runners)
    return unless schema(:runners).any? { |c, _| c == :routing_key }

    alter_table(:runners) do
      drop_index :routing_key, name: :idx_runners_routing_key, if_exists: true
      drop_column :routing_key
    end
  end
end
