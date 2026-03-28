# frozen_string_literal: true

module Legion
  module Data
    module Retention
      DEFAULT_RETENTION_YEARS = 7
      DEFAULT_ARCHIVE_AFTER_DAYS = 90

      class << self
        def archive_old_records(table:, date_column: nil, archive_after_days: DEFAULT_ARCHIVE_AFTER_DAYS)
          db = Legion::Data.connection
          return { archived: 0, table: table } unless db

          date_column ||= if defined?(Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES)
                            Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES[table.to_s] || :created_at
                          else
                            :created_at
                          end

          cutoff = Time.now - (archive_after_days * 86_400)
          archive_table = archive_table_name(table)

          ensure_archive_table!(db, table, archive_table)

          count = 0
          db.transaction do
            records = db[table].where(Sequel.lit("#{date_column} < ?", cutoff))
            count = records.count
            if count.positive?
              db[archive_table].multi_insert(records.all)
              records.delete
            end
          end

          Legion::Logging.info "Archived #{count} row(s) from #{table}" if defined?(Legion::Logging) && count.positive?
          { archived: count, table: table }
        end

        def purge_expired_records(table:, date_column: nil, retention_years: DEFAULT_RETENTION_YEARS)
          db = Legion::Data.connection
          archive_table = archive_table_name(table)
          return { purged: 0, table: table } unless db&.table_exists?(archive_table)

          date_column ||= if defined?(Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES)
                            Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES[table.to_s] || :created_at
                          else
                            :created_at
                          end
          cutoff = Time.now - (retention_years * 365 * 86_400)
          expired = db[archive_table].where(Sequel.lit("#{date_column} < ?", cutoff))
          count = expired.count
          expired.delete if count.positive?
          Legion::Logging.info "Purged #{count} expired row(s) from #{archive_table}" if defined?(Legion::Logging) && count.positive?

          { purged: count, table: table }
        end

        def retention_status(table:, date_column: nil)
          db = Legion::Data.connection
          archive_table = archive_table_name(table)

          date_column ||= if defined?(Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES)
                            Legion::Data::Archival::Policy::DATE_COLUMN_OVERRIDES[table.to_s] || :created_at
                          else
                            :created_at
                          end

          active_count = db&.table_exists?(table) ? db[table].count : 0
          archived_count = db&.table_exists?(archive_table) ? db[archive_table].count : 0

          oldest_active = (db[table].order(Sequel.asc(date_column)).get(date_column) if db&.table_exists?(table) && active_count.positive?)

          oldest_archived = (db[archive_table].order(Sequel.asc(date_column)).get(date_column) if db&.table_exists?(archive_table) && archived_count.positive?)

          {
            table:           table,
            active_count:    active_count,
            archived_count:  archived_count,
            oldest_active:   oldest_active,
            oldest_archived: oldest_archived
          }
        end

        def archive_table_name(table)
          :"#{table}_archive"
        end

        private

        def ensure_archive_table!(db, source_table, archive_table)
          return if db.table_exists?(archive_table)

          source_schema = db.schema(source_table).to_h

          db.create_table(archive_table) do
            source_schema.each do |col_name, col_info|
              column col_name, col_info[:db_type]
            end
            DateTime :archived_at, default: Sequel::CURRENT_TIMESTAMP
          end
        end
      end
    end
  end
end
