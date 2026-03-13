Sequel.migration do
  up do
    create_table(:settings) do
      primary_key :id
      String :key, size: 128, null: false, unique: true
      String :value, size: 256, null: false
      TrueClass :encrypted, null: false, default: false
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end

  down do
    drop_table :settings
  end
end
