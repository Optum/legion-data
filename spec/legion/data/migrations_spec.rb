# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migrations' do
  # By the time spec_helper runs, Legion::Data.setup has auto-migrated to the latest version.
  # This spec verifies that all migrations applied cleanly and the final schema is coherent.

  let(:db) { Legion::Data::Connection.sequel }
  let(:migration_path) { File.expand_path('../../../lib/legion/data/migrations', __dir__) }

  before do
    skip 'no global database connection configured' if db.nil?
  end

  it 'has run all migrations to the latest version' do
    max_migration = Dir.glob(File.join(migration_path, '*.rb'))
                      .map { |f| File.basename(f, '.rb')[/\A(\d+)/, 1]&.to_i }
                      .compact.max
    raise "no migrations found" unless max_migration

    # Sequel default is schema_migrations, but try common variants
    version_table = [:schema_migrations, :schema_info, :sequel_migrations].find { |t| db.table_exists?(t) }
    skip "no migration version table found (#{db.adapter_scheme})" unless version_table

    applied = db[version_table].select_map(:version).map(&:to_i).sort
    expect(applied.last).to eq(max_migration)
  end

  it 'has all expected tables' do
    expected_tables = %i[
      extensions runners functions tasks digital_workers nodes settings value_metrics
      apollo_entries apollo_entries_archive apollo_relations apollo_expertise apollo_access_log
      audit_log audit_records chains
      conversations llm_conversations llm_messages llm_tool_calls llm_tool_call_attempts
      llm_message_inference_requests llm_message_inference_responses llm_route_attempts
      llm_message_inference_metrics llm_conversation_compactions llm_policy_evaluations
      llm_security_events llm_registry_events
      identity_providers identity_provider_capabilities identity_principals identities
      identity_groups identity_group_memberships identity_audit_log
      rbac_role_assignments rbac_runner_grants rbac_cross_team_grants
      memory_traces memory_associations
      metering_records metering_hourly_rollup
      finlog_identities finlog_assets finlog_environments finlog_accounting finlog_executions
      finlog_usages finlog_tags
      webhooks webhook_deliveries webhook_dead_letters
      tenants tasks_archive data_archive archive_manifest audit_archive_manifests
      agent_cluster_nodes agent_cluster_tasks approval_queue
    ]

    expected_tables.each do |table|
      exists = db.table_exists?(table)
      raise "expected table #{table} to exist" unless exists
    end
  end

  it 'has critical indexes on key tables' do
    critical_indexes = {
      llm_tool_calls: ['idx_tool_calls_identity_principal_id'],
      functions: ['idx_functions_component_type'],
    }

    critical_indexes.each do |table, index_names|
      if db.adapter_scheme == :postgres
        indexes = db.indexes(table).keys.map(&:to_s)
      else
        indexes = db[:sqlite_master].where(type: 'index', tbl_name: table.to_s).select_map(:name)
      end

      index_names.each do |name|
        expect(indexes).to include(name), "expected index #{name} on #{table}"
      end
    end
  end
end
