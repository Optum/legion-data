Sequel.migration do
  up do
    create_table(:nodes) do
      primary_key :id
      String :name, size: 128, null: false, default: '', unique: true
      String :status, size: 255, null: false, default: 'unknown', index: true
      TrueClass :active, null: false, default: true, index: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end

  down do
    drop_table :nodes
  end
end
