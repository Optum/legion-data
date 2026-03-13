Sequel.migration do
  up do
    create_table(:extensions) do
      primary_key :id
      TrueClass :active, null: false, default: true, index: true
      String :name, size: 128, null: false, index: true
      String :namespace, size: 128, null: false, default: '', index: true
      String :exchange, size: 255, null: true
      String :uri, size: 256, null: true
      Integer :schema_version, null: false, default: 0, index: true
      DateTime :updated, null: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[name namespace]
    end
  end

  down do
    drop_table :extensions
  end
end
