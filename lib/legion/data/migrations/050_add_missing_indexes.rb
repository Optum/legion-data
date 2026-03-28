# frozen_string_literal: true

Sequel.migration do
  up do
    # runners: FK without index, hot-path lookups, duplicate prevention
    if table_exists?(:runners)
      alter_table(:runners) do
        add_index :extension_id, name: :idx_runners_extension_id, if_not_exists: true
        add_index :namespace, name: :idx_runners_namespace, if_not_exists: true
        add_index :name, name: :idx_runners_name, if_not_exists: true
        add_index %i[extension_id name], name: :idx_runners_extension_name, unique: true, if_not_exists: true
      end
    end

    # tasks: plain Integer relationship_id used by ORM association
    if table_exists?(:tasks)
      alter_table(:tasks) do
        add_index :relationship_id, name: :idx_tasks_relationship_id, if_not_exists: true
      end
    end

    # digital_workers: consent/trust-based queries
    if table_exists?(:digital_workers)
      alter_table(:digital_workers) do
        add_index :consent_tier, name: :idx_digital_workers_consent_tier, if_not_exists: true
        add_index :trust_score, name: :idx_digital_workers_trust_score, if_not_exists: true
      end
    end

    # audit_log: composite principal+time query, action/node lookups
    if table_exists?(:audit_log)
      alter_table(:audit_log) do
        add_index %i[principal_id created_at], name: :idx_audit_log_principal_time, if_not_exists: true
        add_index :action, name: :idx_audit_log_action, if_not_exists: true
        add_index :node, name: :idx_audit_log_node, if_not_exists: true
      end
    end

    # webhook_deliveries: event/time/success filtering
    if table_exists?(:webhook_deliveries)
      alter_table(:webhook_deliveries) do
        add_index :event_name, name: :idx_webhook_deliveries_event_name, if_not_exists: true
        add_index :delivered_at, name: :idx_webhook_deliveries_delivered_at, if_not_exists: true
        add_index :success, name: :idx_webhook_deliveries_success, if_not_exists: true
      end
    end

    # webhook_dead_letters: event/time filtering
    if table_exists?(:webhook_dead_letters)
      alter_table(:webhook_dead_letters) do
        add_index :event_name, name: :idx_webhook_dead_letters_event_name, if_not_exists: true
        add_index :created_at, name: :idx_webhook_dead_letters_created_at, if_not_exists: true
      end
    end

    # conversations: identity and recency lookups
    if table_exists?(:conversations)
      alter_table(:conversations) do
        add_index :caller_identity, name: :idx_conversations_caller_identity, if_not_exists: true
        add_index :updated_at, name: :idx_conversations_updated_at, if_not_exists: true
      end
    end

    # approval_queue: requester/reviewer lookups
    if table_exists?(:approval_queue)
      alter_table(:approval_queue) do
        add_index :requester_id, name: :idx_approval_queue_requester_id, if_not_exists: true
        add_index :reviewer_id, name: :idx_approval_queue_reviewer_id, if_not_exists: true
      end
    end

    # rbac_role_assignments: role and expiry lookups
    if table_exists?(:rbac_role_assignments)
      alter_table(:rbac_role_assignments) do
        add_index :role, name: :idx_rbac_role_assignments_role, if_not_exists: true
        add_index :expires_at, name: :idx_rbac_role_assignments_expires_at, if_not_exists: true
      end
    end

    # rbac_cross_team_grants: target team and expiry lookups
    if table_exists?(:rbac_cross_team_grants)
      alter_table(:rbac_cross_team_grants) do
        add_index :target_team, name: :idx_rbac_cross_team_grants_target_team, if_not_exists: true
        add_index :expires_at, name: :idx_rbac_cross_team_grants_expires_at, if_not_exists: true
      end
    end

    # memory_traces: consolidation and source agent lookups
    if table_exists?(:memory_traces)
      existing_cols = schema(:memory_traces).map(&:first)

      if existing_cols.include?(:consolidation_candidate)
        alter_table(:memory_traces) do
          add_index :consolidation_candidate, name: :idx_memory_traces_consolidation, if_not_exists: true
        end
      end

      if existing_cols.include?(:source_agent_id)
        alter_table(:memory_traces) do
          add_index :source_agent_id, name: :idx_memory_traces_source_agent_id, if_not_exists: true
        end
      end
    end

    # agent_cluster_tasks: time-based querying
    if table_exists?(:agent_cluster_tasks)
      alter_table(:agent_cluster_tasks) do
        add_index :created_at, name: :idx_agent_cluster_tasks_created_at, if_not_exists: true
      end
    end

    # finlog_executions: environment_id FK without index
    if table_exists?(:finlog_executions)
      alter_table(:finlog_executions) do
        add_index :environment_id, name: :idx_finlog_exec_environment_id, if_not_exists: true
      end
    end
  end

  down do
    [
      [:runners, %i[
        idx_runners_extension_id idx_runners_namespace idx_runners_name idx_runners_extension_name
      ]],
      [:tasks, %i[idx_tasks_relationship_id]],
      [:digital_workers, %i[idx_digital_workers_consent_tier idx_digital_workers_trust_score]],
      [:audit_log, %i[idx_audit_log_principal_time idx_audit_log_action idx_audit_log_node]],
      [:webhook_deliveries, %i[
        idx_webhook_deliveries_event_name idx_webhook_deliveries_delivered_at idx_webhook_deliveries_success
      ]],
      [:webhook_dead_letters, %i[
        idx_webhook_dead_letters_event_name idx_webhook_dead_letters_created_at
      ]],
      [:conversations, %i[idx_conversations_caller_identity idx_conversations_updated_at]],
      [:approval_queue, %i[idx_approval_queue_requester_id idx_approval_queue_reviewer_id]],
      [:rbac_role_assignments, %i[idx_rbac_role_assignments_role idx_rbac_role_assignments_expires_at]],
      [:rbac_cross_team_grants, %i[
        idx_rbac_cross_team_grants_target_team idx_rbac_cross_team_grants_expires_at
      ]],
      [:memory_traces, %i[idx_memory_traces_consolidation idx_memory_traces_source_agent_id]],
      [:agent_cluster_tasks, %i[idx_agent_cluster_tasks_created_at]],
      [:finlog_executions, %i[idx_finlog_exec_environment_id]]
    ].each do |table, indexes|
      next unless table_exists?(table)

      alter_table(table) do
        indexes.each do |idx_name|
          drop_index [], name: idx_name, if_exists: true
        end
      end
    end
  end
end
