# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 097: add LLM dispatch fields' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 97)
  end

  it 'adds fleet dispatch identifiers to inference requests' do
    columns = db.schema(:llm_message_inference_requests).map(&:first)

    expect(columns).to include(:operation, :correlation_id, :idempotency_key)
  end

  it 'adds provider instance dispatch fields to inference responses' do
    columns = db.schema(:llm_message_inference_responses).map(&:first)

    expect(columns).to include(:provider_instance, :dispatch_path, :response_thinking_json)
  end
end
