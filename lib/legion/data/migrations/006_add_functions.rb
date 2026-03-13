Sequel.migration do
  up do
    create_table(:functions) do
      primary_key :id
      String :name, size: 128, null: false, index: true
      TrueClass :active, null: false, default: true, index: true
      foreign_key :runner_id, :runners, null: false, on_delete: :cascade, on_update: :cascade, index: true
      String :args, text: true, null: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true

      unique %i[runner_id name]
    end
  end

  down do
    drop_table :functions
  end
end
