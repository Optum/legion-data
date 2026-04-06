Sequel.migration do
  change do
    create_table(:tool_embedding_cache) do
      primary_key :id
      String :content_hash, size: 32, null: false
      String :model, size: 100, null: false
      String :tool_name, size: 200, null: false
      column :vector, :text, null: false
      DateTime :embedded_at, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      unique %i[content_hash model]
      index :tool_name
    end
  end
end
