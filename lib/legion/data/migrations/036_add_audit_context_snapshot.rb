# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:audit_log) do
      add_column :context_snapshot, :text, null: true
    end
  end

  down do
    alter_table(:audit_log) do
      drop_column :context_snapshot
    end
  end
end
