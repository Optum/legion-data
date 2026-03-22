# frozen_string_literal: true

module Legion
  module Data
    module StorageTiers
      TIERS = { hot: 0, warm: 1, cold: 2 }.freeze

      class << self
        def archive_to_warm(table:, age_days: 90, batch_size: 1000)
          return { archived: 0, reason: 'no_connection' } unless Legion::Data.connection
          return { archived: 0, reason: 'no_archive_table' } unless Legion::Data.connection.table_exists?(:data_archive)

          cutoff = Time.now - (age_days * 86_400)
          records = Legion::Data.connection[table].where { created_at < cutoff }.limit(batch_size).all
          return { archived: 0 } if records.empty?

          Legion::Data.connection.transaction do
            records.each do |record|
              Legion::Data.connection[:data_archive].insert(
                source_table: table.to_s, source_id: record[:id],
                data:         Legion::JSON.dump(record),
                tier:         TIERS[:warm],
                archived_at:  Time.now.utc
              )
            end

            ids = records.map { |r| r[:id] }
            Legion::Data.connection[table].where(id: ids).delete
          end

          Legion::Logging.info "Archived #{records.size} row(s) from #{table} to warm tier" if defined?(Legion::Logging)
          { archived: records.size, table: table.to_s }
        end

        def export_to_cold(age_days: 365, batch_size: 5000)
          return { exported: 0 } unless Legion::Data.connection&.table_exists?(:data_archive)

          cutoff = Time.now - (age_days * 86_400)
          records = Legion::Data.connection[:data_archive]
                                .where(tier: TIERS[:warm])
                                .where { archived_at < cutoff }
                                .limit(batch_size).all
          return { exported: 0 } if records.empty?

          ids = records.map { |r| r[:id] }
          Legion::Data.connection[:data_archive].where(id: ids).update(tier: TIERS[:cold])
          Legion::Logging.info "Exported #{records.size} row(s) to cold tier" if defined?(Legion::Logging)
          { exported: records.size, data: records }
        end

        def stats
          return {} unless Legion::Data.connection&.table_exists?(:data_archive)

          { warm: count_tier(:warm), cold: count_tier(:cold) }
        end

        private

        def count_tier(tier)
          Legion::Data.connection[:data_archive].where(tier: TIERS[tier]).count
        rescue StandardError => e
          Legion::Logging.debug("StorageTiers#count_tier failed for #{tier}: #{e.message}") if defined?(Legion::Logging)
          0
        end
      end
    end
  end
end
