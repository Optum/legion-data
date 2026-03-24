# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:conversations) do
      String :id, primary_key: true, size: 64
      String :caller_identity, size: 255
      String :metadata, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:conversation_messages) do
      primary_key :id
      String :conversation_id, size: 64, null: false
      Integer :seq, null: false
      String :role, size: 32, null: false
      String :content, text: true
      String :provider, size: 64
      String :model, size: 128
      Integer :input_tokens
      Integer :output_tokens
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      index [:conversation_id, :seq], unique: true
      foreign_key [:conversation_id], :conversations, key: :id
    end
  end

  down do
    drop_table(:conversation_messages)
    drop_table(:conversations)
  end
end
