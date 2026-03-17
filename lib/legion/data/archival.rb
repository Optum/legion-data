# frozen_string_literal: true

require_relative 'archival/policy'

module Legion
  module Data
    module Archival
      ARCHIVE_TABLE_MAP = {
        tasks:            :tasks_archive,
        metering_records: :metering_records_archive
      }.freeze

      class << self
        def archive!(policy: Policy.new, dry_run: false)
          results = {}
          policy.tables.each do |table_name|
            table = table_name.to_sym
            archive_table = ARCHIVE_TABLE_MAP[table]
            next unless archive_table && db_ready?(table) && db_ready?(archive_table)

            count = archive_table!(
              source: table, destination: archive_table,
              cutoff: policy.warm_cutoff, batch_size: policy.batch_size, dry_run: dry_run
            )
            results[table] = count
          end
          results
        end

        def restore(table:, ids:)
          source_table = table.to_sym
          archive_table = ARCHIVE_TABLE_MAP[source_table]
          return 0 unless archive_table && db_ready?(archive_table)

          conn = Legion::Data.connection
          restored = 0
          conn.transaction do
            conn[archive_table].where(original_id: ids).each do |row|
              restore_row = row.except(:id, :archived_at, :original_id, :original_created_at, :original_updated_at)
              restore_row[:id] = row[:original_id]
              restore_row[:created_at] = row[:original_created_at]
              restore_row[:updated_at] = row[:original_updated_at]
              conn[source_table].insert(restore_row)
              restored += 1
            end
            conn[archive_table].where(original_id: ids).delete
          end
          restored
        end

        def search(table:, where: {})
          source_table = table.to_sym
          archive_table = ARCHIVE_TABLE_MAP[source_table]
          return [] unless db_ready?(source_table)

          conn = Legion::Data.connection
          hot = conn[source_table].where(where).all
          warm = db_ready?(archive_table) ? conn[archive_table].where(where).all : []
          hot + warm
        end

        private

        def archive_table!(source:, destination:, cutoff:, batch_size:, dry_run:)
          conn = Legion::Data.connection
          candidates = conn[source].where { created_at < cutoff }.limit(batch_size)
          count = candidates.count
          return count if dry_run || count.zero?

          conn.transaction do
            candidates.each do |row|
              archive_row = row.dup
              archive_row[:original_id] = archive_row.delete(:id)
              archive_row[:original_created_at] = archive_row.delete(:created_at)
              archive_row[:original_updated_at] = archive_row.delete(:updated_at)
              archive_row[:archived_at] = Time.now
              conn[destination].insert(archive_row)
            end
            conn[source].where(id: candidates.select(:id)).delete
          end
          count
        end

        def db_ready?(table)
          defined?(Legion::Data) && Legion::Data.connection&.table_exists?(table)
        rescue StandardError
          false
        end
      end
    end
  end
end
