# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :chains do
      primary_key :id
      String :name, null: false, size: 255, index: true
      TrueClass :active, null: false, default: true, index: true
      DateTime :created, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated, null: true
    end
  end
end
