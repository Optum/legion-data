Sequel.migration do
  up do
    create_table(:tasks) do
      primary_key :id
      Integer :relationship_id, null: true
      foreign_key :function_id, :functions, null: true
      String :status, size: 255, null: false, index: true
      foreign_key :parent_id, :tasks, null: true, on_delete: :set_null, on_update: :cascade, index: true
      foreign_key :master_id, :tasks, null: true, on_delete: :set_null, on_update: :cascade, index: true
      String :function_args, text: true, null: true
      String :results, text: true, null: true
      String :payload, text: true, null: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end

  down do
    drop_table :tasks
  end
end
