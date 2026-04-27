# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    apollo_columns = schema(:apollo_entries).map(&:first)
    alter_table(:apollo_entries) do
      set_column_type :content_hash, String, fixed: true, size: 64 if apollo_columns.include?(:content_hash)
      set_column_type :knowledge_domain, String, size: 255 if apollo_columns.include?(:knowledge_domain)
      set_column_type :source_provider, String, size: 255 if apollo_columns.include?(:source_provider)
      set_column_type :source_agent, String, size: 255 if apollo_columns.include?(:source_agent)
    end

    next unless table_exists?(:apollo_entries_archive)

    archive_columns = schema(:apollo_entries_archive).map(&:first)
    alter_table(:apollo_entries_archive) do
      set_column_type :content_hash, String, fixed: true, size: 64 if archive_columns.include?(:content_hash)
      set_column_type :knowledge_domain, String, size: 255 if archive_columns.include?(:knowledge_domain)
      set_column_type :source_provider, String, size: 255 if archive_columns.include?(:source_provider)
      set_column_type :source_agent, String, size: 255 if archive_columns.include?(:source_agent)
    end
  end

  down do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    apollo_columns = schema(:apollo_entries).map(&:first)
    alter_table(:apollo_entries) do
      set_column_type :content_hash, String, fixed: true, size: 32 if apollo_columns.include?(:content_hash)
      set_column_type :knowledge_domain, String, size: 50 if apollo_columns.include?(:knowledge_domain)
      set_column_type :source_provider, String, size: 50 if apollo_columns.include?(:source_provider)
      set_column_type :source_agent, String, size: 50 if apollo_columns.include?(:source_agent)
    end

    next unless table_exists?(:apollo_entries_archive)

    archive_columns = schema(:apollo_entries_archive).map(&:first)
    alter_table(:apollo_entries_archive) do
      set_column_type :content_hash, String, fixed: true, size: 32 if archive_columns.include?(:content_hash)
      set_column_type :knowledge_domain, String, size: 50 if archive_columns.include?(:knowledge_domain)
      set_column_type :source_provider, String, size: 50 if archive_columns.include?(:source_provider)
      set_column_type :source_agent, String, size: 50 if archive_columns.include?(:source_agent)
    end
  end
end
