# frozen_string_literal: true

module Legion
  module Data
    module Rls
      RLS_TABLES = %i[
        tasks digital_workers audit_log memory_traces extensions
        functions runners nodes settings value_metrics
      ].freeze

      module_function

      def rls_enabled?
        return false unless Legion::Settings[:data][:connected]

        Legion::Data.connection.adapter_scheme == :postgres
      rescue StandardError
        false
      end

      def assign_tenant(tenant_id)
        return unless rls_enabled?

        Legion::Data.connection.run(
          Sequel.lit('SET app.current_tenant = ?', tenant_id.to_s)
        )
      end

      def current_tenant
        return nil unless rls_enabled?

        Legion::Data.connection.fetch('SHOW app.current_tenant').first&.values&.first
      rescue Sequel::DatabaseError
        nil
      end

      def reset_tenant
        return unless rls_enabled?

        Legion::Data.connection.run('RESET app.current_tenant')
      end

      def with_tenant(tenant_id)
        previous = current_tenant
        assign_tenant(tenant_id)
        yield
      ensure
        previous ? assign_tenant(previous) : reset_tenant
      end
    end
  end
end
