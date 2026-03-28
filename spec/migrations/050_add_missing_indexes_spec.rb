# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 050: add missing indexes' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 50)
  end

  describe 'runners table' do
    it 'has index on extension_id' do
      expect(db.indexes(:runners)).to have_key(:idx_runners_extension_id)
    end

    it 'has index on namespace' do
      expect(db.indexes(:runners)).to have_key(:idx_runners_namespace)
    end

    it 'has index on name' do
      expect(db.indexes(:runners)).to have_key(:idx_runners_name)
    end

    it 'has unique composite index on extension_id and name' do
      idx = db.indexes(:runners)[:idx_runners_extension_name]
      expect(idx).not_to be_nil
      expect(idx[:unique]).to be true
    end
  end

  describe 'tasks table' do
    it 'has index on relationship_id' do
      expect(db.indexes(:tasks)).to have_key(:idx_tasks_relationship_id)
    end
  end

  describe 'digital_workers table' do
    it 'has index on consent_tier' do
      expect(db.indexes(:digital_workers)).to have_key(:idx_digital_workers_consent_tier)
    end

    it 'has index on trust_score' do
      expect(db.indexes(:digital_workers)).to have_key(:idx_digital_workers_trust_score)
    end
  end

  describe 'audit_log table' do
    it 'has composite index on principal_id and created_at' do
      expect(db.indexes(:audit_log)).to have_key(:idx_audit_log_principal_time)
    end

    it 'has index on action' do
      expect(db.indexes(:audit_log)).to have_key(:idx_audit_log_action)
    end

    it 'has index on node' do
      expect(db.indexes(:audit_log)).to have_key(:idx_audit_log_node)
    end
  end

  describe 'webhook_deliveries table' do
    it 'has index on event_name' do
      expect(db.indexes(:webhook_deliveries)).to have_key(:idx_webhook_deliveries_event_name)
    end

    it 'has index on delivered_at' do
      expect(db.indexes(:webhook_deliveries)).to have_key(:idx_webhook_deliveries_delivered_at)
    end

    it 'has index on success' do
      expect(db.indexes(:webhook_deliveries)).to have_key(:idx_webhook_deliveries_success)
    end
  end

  describe 'webhook_dead_letters table' do
    it 'has index on event_name' do
      expect(db.indexes(:webhook_dead_letters)).to have_key(:idx_webhook_dead_letters_event_name)
    end

    it 'has index on created_at' do
      expect(db.indexes(:webhook_dead_letters)).to have_key(:idx_webhook_dead_letters_created_at)
    end
  end

  describe 'conversations table' do
    it 'has index on caller_identity' do
      expect(db.indexes(:conversations)).to have_key(:idx_conversations_caller_identity)
    end

    it 'has index on updated_at' do
      expect(db.indexes(:conversations)).to have_key(:idx_conversations_updated_at)
    end
  end

  describe 'approval_queue table' do
    it 'has index on requester_id' do
      expect(db.indexes(:approval_queue)).to have_key(:idx_approval_queue_requester_id)
    end

    it 'has index on reviewer_id' do
      expect(db.indexes(:approval_queue)).to have_key(:idx_approval_queue_reviewer_id)
    end
  end

  describe 'rbac_role_assignments table' do
    it 'has index on role' do
      expect(db.indexes(:rbac_role_assignments)).to have_key(:idx_rbac_role_assignments_role)
    end

    it 'has index on expires_at' do
      expect(db.indexes(:rbac_role_assignments)).to have_key(:idx_rbac_role_assignments_expires_at)
    end
  end

  describe 'rbac_cross_team_grants table' do
    it 'has index on target_team' do
      expect(db.indexes(:rbac_cross_team_grants)).to have_key(:idx_rbac_cross_team_grants_target_team)
    end

    it 'has index on expires_at' do
      expect(db.indexes(:rbac_cross_team_grants)).to have_key(:idx_rbac_cross_team_grants_expires_at)
    end
  end

  describe 'memory_traces table (conditional columns)' do
    it 'has index on consolidation_candidate if column exists' do
      cols = db.schema(:memory_traces).map(&:first)
      next unless cols.include?(:consolidation_candidate)

      expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_consolidation)
    end

    it 'has index on source_agent_id if column exists' do
      cols = db.schema(:memory_traces).map(&:first)
      next unless cols.include?(:source_agent_id)

      expect(db.indexes(:memory_traces)).to have_key(:idx_memory_traces_source_agent_id)
    end
  end

  describe 'agent_cluster_tasks table' do
    it 'has index on created_at' do
      expect(db.indexes(:agent_cluster_tasks)).to have_key(:idx_agent_cluster_tasks_created_at)
    end
  end

  describe 'finlog_executions table' do
    it 'has index on environment_id' do
      expect(db.indexes(:finlog_executions)).to have_key(:idx_finlog_exec_environment_id)
    end
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 50)
    end.not_to raise_error
  end
end
