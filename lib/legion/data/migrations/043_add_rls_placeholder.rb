# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    tables = %i[
      tasks digital_workers audit_log memory_traces extensions
      functions runners nodes settings value_metrics
    ]

    tables.each do |table|
      next unless table_exists?(table)
      next unless schema(table).any? { |col, _| col == :tenant_id }

      run "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY"
      run <<~SQL
        DO $$ BEGIN
          IF NOT EXISTS (
            SELECT 1 FROM pg_policies WHERE tablename = '#{table}' AND policyname = 'tenant_isolation_#{table}'
          ) THEN
            CREATE POLICY tenant_isolation_#{table} ON #{table}
              USING (tenant_id = current_setting('app.current_tenant', true));
          END IF;
        END $$;
      SQL
    end
  end

  down do
    next unless adapter_scheme == :postgres

    tables = %i[
      tasks digital_workers audit_log memory_traces extensions
      functions runners nodes settings value_metrics
    ]

    tables.each do |table|
      next unless table_exists?(table)

      run "DROP POLICY IF EXISTS tenant_isolation_#{table} ON #{table}"
      run "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY"
    end
  end
end
