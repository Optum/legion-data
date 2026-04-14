# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:approval_queue) do
      add_column :resume_routing_key, String, size: 255, null: true
      add_column :resume_exchange, String, size: 255, null: true
    end
  end

  down do
    alter_table(:approval_queue) do
      drop_column :resume_routing_key
      drop_column :resume_exchange
    end
  end
end
