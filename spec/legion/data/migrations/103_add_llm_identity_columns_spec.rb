# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migrations 103-114: LLM lifecycle identity columns' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 114)
  end

  def index_names(table)
    if db.adapter_scheme == :postgres
      db.indexes(table).keys.map(&:to_s)
    else
      db[:sqlite_master].where(type: 'index', tbl_name: table.to_s).select_map(:name)
    end
  end

  context 'migration 103: llm_conversations' do
    subject(:columns) { db.schema(:llm_conversations).to_h }

    it 'adds access_scope with default global' do
      expect(columns).to have_key(:access_scope)
      expect(columns[:access_scope][:allow_null]).to be false
      expect(columns[:access_scope][:default].delete("'")).to eq('global')
    end

    it 'adds identity_canonical_name as nullable varchar' do
      expect(columns).to have_key(:identity_canonical_name)
      expect(columns[:identity_canonical_name][:allow_null]).to be true
    end

    it 'preserves existing principal_id column' do
      expect(columns).to have_key(:principal_id)
    end

    it 'preserves existing identity_id column' do
      expect(columns).to have_key(:identity_id)
    end

    it 'creates index on access_scope' do
      expect(index_names(:llm_conversations)).to include('idx_conversations_access_scope')
    end
  end

  context 'migration 104: llm_messages' do
    subject(:columns) { db.schema(:llm_messages).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_messages)).to include('idx_messages_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_messages)).to include('idx_messages_identity_principal_id')
    end
  end

  context 'migration 105: llm_message_inference_requests' do
    subject(:columns) { db.schema(:llm_message_inference_requests).to_h }

    it 'adds access_scope with default global' do
      expect(columns).to have_key(:access_scope)
      expect(columns[:access_scope][:allow_null]).to be false
      expect(columns[:access_scope][:default].delete("'")).to eq('global')
    end

    it 'adds identity_canonical_name as nullable varchar' do
      expect(columns).to have_key(:identity_canonical_name)
      expect(columns[:identity_canonical_name][:allow_null]).to be true
    end

    it 'preserves existing caller_principal_id column' do
      expect(columns).to have_key(:caller_principal_id)
    end

    it 'preserves existing caller_identity_id column' do
      expect(columns).to have_key(:caller_identity_id)
    end

    it 'creates index on access_scope' do
      expect(index_names(:llm_message_inference_requests)).to include('idx_inference_requests_access_scope')
    end
  end

  context 'migration 106: llm_message_inference_responses' do
    subject(:columns) { db.schema(:llm_message_inference_responses).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_message_inference_responses)).to include('idx_message_inference_responses_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_message_inference_responses)).to include('idx_message_inference_responses_identity_principal_id')
    end
  end

  context 'migration 107: llm_route_attempts' do
    subject(:columns) { db.schema(:llm_route_attempts).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_route_attempts)).to include('idx_route_attempts_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_route_attempts)).to include('idx_route_attempts_identity_principal_id')
    end
  end

  context 'migration 108: llm_message_inference_metrics' do
    subject(:columns) { db.schema(:llm_message_inference_metrics).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_message_inference_metrics)).to include('idx_message_inference_metrics_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_message_inference_metrics)).to include('idx_message_inference_metrics_identity_principal_id')
    end
  end

  context 'migration 109: llm_tool_calls' do
    subject(:columns) { db.schema(:llm_tool_calls).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_tool_calls)).to include('idx_tool_calls_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_tool_calls)).to include('idx_tool_calls_identity_principal_id')
    end
  end

  context 'migration 110: llm_tool_call_attempts' do
    subject(:columns) { db.schema(:llm_tool_call_attempts).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_tool_call_attempts)).to include('idx_tool_call_attempts_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_tool_call_attempts)).to include('idx_tool_call_attempts_identity_principal_id')
    end
  end

  context 'migration 111: llm_conversation_compactions' do
    subject(:columns) { db.schema(:llm_conversation_compactions).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_conversation_compactions)).to include('idx_conversation_compactions_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_conversation_compactions)).to include('idx_conversation_compactions_identity_principal_id')
    end
  end

  context 'migration 112: llm_policy_evaluations' do
    subject(:columns) { db.schema(:llm_policy_evaluations).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_policy_evaluations)).to include('idx_policy_evaluations_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_policy_evaluations)).to include('idx_policy_evaluations_identity_principal_id')
    end
  end

  context 'migration 113: llm_security_events' do
    subject(:columns) { db.schema(:llm_security_events).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_security_events)).to include('idx_security_events_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_security_events)).to include('idx_security_events_identity_principal_id')
    end
  end

  context 'migration 114: llm_registry_events' do
    subject(:columns) { db.schema(:llm_registry_events).to_h }

    it 'adds access_scope with default global' do
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

    it 'creates index on access_scope' do
      expect(index_names(:llm_registry_events)).to include('idx_registry_events_access_scope')
    end

    it 'creates partial index on identity_principal_id' do
      expect(index_names(:llm_registry_events)).to include('idx_registry_events_identity_principal_id')
    end
  end
end
