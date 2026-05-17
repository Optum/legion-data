# frozen_string_literal: true

require 'spec_helper'

# Tables that received the full set of four identity columns
LLM_IDENTITY_FULL_SET_TABLES = %i[
  llm_messages
  llm_message_inference_responses
  llm_message_inference_metrics
  llm_tool_calls
  llm_tool_call_attempts
  llm_policy_evaluations
  llm_security_events
  llm_registry_events
  llm_route_attempts
  llm_conversation_compactions
].freeze

# Tables that received only access_scope + identity_canonical_name
LLM_IDENTITY_PARTIAL_SET_TABLES = %i[
  llm_conversations
  llm_message_inference_requests
].freeze

RSpec.describe 'Migration 103: LLM lifecycle identity columns' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 103)
  end

  def index_names(table)
    if db.adapter_scheme == :postgres
      db.indexes(table).keys.map(&:to_s)
    else
      db[:sqlite_master].where(type: 'index', tbl_name: table.to_s).select_map(:name)
    end
  end

  context 'full-set tables receive all four identity columns' do
    LLM_IDENTITY_FULL_SET_TABLES.each do |table|
      context table.to_s do
        subject(:columns) { db.schema(table).to_h }

        it 'adds access_scope with default global and not null' do
          expect(columns).to have_key(:access_scope)
          expect(columns[:access_scope][:allow_null]).to be false
          expect(columns[:access_scope][:default].delete("'")).to eq('global')
        end

        it 'adds identity_principal_id as nullable integer' do
          expect(columns).to have_key(:identity_principal_id)
          expect(columns[:identity_principal_id][:allow_null]).to be true
        end

        it 'adds identity_id as nullable integer' do
          expect(columns).to have_key(:identity_id)
          expect(columns[:identity_id][:allow_null]).to be true
        end

        it 'adds identity_canonical_name as nullable varchar' do
          expect(columns).to have_key(:identity_canonical_name)
          expect(columns[:identity_canonical_name][:allow_null]).to be true
        end

        it 'creates an index on access_scope' do
          short = table.to_s.sub('llm_', '')
          expect(index_names(table)).to include("idx_#{short}_access_scope")
        end

        it 'creates a partial index on identity_principal_id' do
          short = table.to_s.sub('llm_', '')
          expect(index_names(table)).to include("idx_#{short}_identity_principal_id")
        end
      end
    end
  end

  context 'partial-set tables receive access_scope and identity_canonical_name only' do
    LLM_IDENTITY_PARTIAL_SET_TABLES.each do |table|
      context table.to_s do
        subject(:columns) { db.schema(table).to_h }

        it 'adds access_scope with default global and not null' do
          expect(columns).to have_key(:access_scope)
          expect(columns[:access_scope][:allow_null]).to be false
          expect(columns[:access_scope][:default].delete("'")).to eq('global')
        end

        it 'adds identity_canonical_name as nullable varchar' do
          expect(columns).to have_key(:identity_canonical_name)
          expect(columns[:identity_canonical_name][:allow_null]).to be true
        end
      end
    end

    it 'preserves existing principal_id column on llm_conversations' do
      expect(db.schema(:llm_conversations).to_h).to have_key(:principal_id)
    end

    it 'preserves existing identity_id column on llm_conversations' do
      expect(db.schema(:llm_conversations).to_h).to have_key(:identity_id)
    end

    it 'preserves existing caller_principal_id column on llm_message_inference_requests' do
      expect(db.schema(:llm_message_inference_requests).to_h).to have_key(:caller_principal_id)
    end

    it 'preserves existing caller_identity_id column on llm_message_inference_requests' do
      expect(db.schema(:llm_message_inference_requests).to_h).to have_key(:caller_identity_id)
    end

    it 'creates an index on access_scope for llm_conversations' do
      expect(index_names(:llm_conversations)).to include('idx_conversations_access_scope')
    end

    it 'creates an index on access_scope for llm_message_inference_requests' do
      expect(index_names(:llm_message_inference_requests)).to include('idx_inference_requests_access_scope')
    end
  end
end
