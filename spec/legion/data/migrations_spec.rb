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
                       .filter_map { |f| File.basename(f, '.rb')[/\A(\d+)/, 1]&.to_i }
                       .max
    raise 'no migrations found' unless max_migration

    # Sequel default is schema_migrations, but try common variants
    version_table = %i[schema_migrations schema_info sequel_migrations].find { |t| db.table_exists?(t) }
    skip "no migration version table found (#{db.adapter_scheme})" unless version_table

    applied = db[version_table].select_map(:version).map(&:to_i).sort
    expect(applied.last).to eq(max_migration)
  end

  it 'has all expected tables' do
    # Derive expected tables by scanning migration files for create_table and drop_table calls.
    # Tables dropped in later migrations are excluded.
    migration_files = Dir.glob(File.join(migration_path, '*.rb')).sort
    created = {}
    dropped = Set.new

    migration_files.each do |file|
      basename = File.basename(file, '.rb')
      num = basename[/\A(\d+)/, 1] || '000'
      content = File.read(file)

      content.scan(/create_table\?\s*\(\s*:?(\w+)/).flatten.each { |t| created[t] = num }
      content.scan(/create_table\s*\(\s*:?(\w+)/).each do |match|
        t = match[0]
        # Skip guarded creates (next if/return if/next unless before create_table)
        next if t == '?'
        created[t] = num unless created.key?(t)
      end

      content.scan(/drop_table\s*\(\s*:?(\w+)/).each do |match|
        t = match[0]
        next if t == '?'
        dropped << t
      end
    end

    expected_tables = (created.keys.to_a - dropped.to_a - %w[sequel_migrations schema_migrations]).sort

    expected_tables.each do |table|
      exists = db.table_exists?(table.to_sym)
      raise "expected table #{table} to exist (created in migration #{created[table]})" unless exists
    end
  end

  it 'has critical indexes on key tables' do
    critical_indexes = {
      llm_tool_calls: ['idx_tool_calls_identity_principal_id'],
      functions:      ['idx_functions_component_type']
    }

    critical_indexes.each do |table, index_names|
      indexes = if db.adapter_scheme == :postgres
                  db.indexes(table).keys.map(&:to_s)
                else
                  db[:sqlite_master].where(type: 'index', tbl_name: table.to_s).select_map(:name)
                end

      index_names.each do |name|
        expect(indexes).to include(name), "expected index #{name} on #{table}"
      end
    end
  end
end
