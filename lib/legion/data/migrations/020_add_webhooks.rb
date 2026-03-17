# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:webhooks) do
      primary_key :id
      String :url, null: false, size: 2048
      String :secret, null: false, size: 255
      String :event_types, text: true
      String :status, default: 'active', size: 20
      Integer :max_retries, default: 5
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:webhook_deliveries) do
      primary_key :id
      foreign_key :webhook_id, :webhooks, null: false, index: true
      String :event_name, null: false, size: 255
      Integer :response_status
      TrueClass :success
      Integer :attempt, default: 1
      String :error, text: true
      DateTime :delivered_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:webhook_dead_letters) do
      primary_key :id
      foreign_key :webhook_id, :webhooks, null: false, index: true
      String :event_name, null: false, size: 255
      String :payload, text: true
      Integer :attempts
      String :last_error, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
