# frozen_string_literal: true

require 'legion/logging/helper'

module Legion
  module Data
    module PartitionManager
      NOT_POSTGRES = { skipped: true, reason: 'not_postgres' }.freeze

      class << self
        include Legion::Logging::Helper

        def ensure_partitions(table:, months_ahead: 3)
          return NOT_POSTGRES unless postgres?

          created = []
          existing = []
          base = Date.today

          months_ahead.times do |i|
            target = advance_months(base, i)
            partition = partition_name(table, target)
            from_str  = target.strftime('%Y-%m-%d')
            to_str    = advance_months(target, 1).strftime('%Y-%m-%d')

            ddl = "CREATE TABLE IF NOT EXISTS #{partition} " \
                  "PARTITION OF #{table} " \
                  "FOR VALUES FROM ('#{from_str}') TO ('#{to_str}')"

            before_count = partition_names_for(table).size
            Legion::Data.connection.run(ddl)
            after_count = partition_names_for(table).size

            if after_count > before_count
              log.info("Created partition #{partition}")
              created << partition
            else
              existing << partition
            end
          end

          log.info "PartitionManager ensure_partitions table=#{table} created=#{created.size} existing=#{existing.size}"
          { created: created, existing: existing }
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :ensure_partitions, table: table, months_ahead: months_ahead)
          { created: [], existing: [], error: e.message }
        end

        def drop_old_partitions(table:, retention_months: 24)
          return NOT_POSTGRES unless postgres?

          cutoff = advance_months(Date.today, -retention_months)
          dropped = []
          retained = []

          partition_names_for(table).each do |part|
            part_date = parse_partition_date(part)
            next unless part_date

            if part_date < cutoff
              Legion::Data.connection.run("DROP TABLE #{part}")
              log.info("Dropped partition #{part}")
              dropped << part
            else
              retained << part
            end
          end

          log.info "PartitionManager drop_old_partitions table=#{table} dropped=#{dropped.size} retained=#{retained.size}"
          { dropped: dropped, retained: retained }
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :drop_old_partitions, table: table, retention_months: retention_months)
          { dropped: [], retained: [], error: e.message }
        end

        def list_partitions(table:)
          return NOT_POSTGRES unless postgres?

          sql = <<~SQL
            SELECT c.relname AS name,
                   pg_get_expr(c.relpartbound, c.oid) AS bound
            FROM   pg_inherits i
            JOIN   pg_class    p ON p.oid = i.inhparent
            JOIN   pg_class    c ON c.oid = i.inhrelid
            WHERE  p.relname = '#{table}'
            ORDER  BY c.relname
          SQL

          partitions = Legion::Data.connection.fetch(sql).map do |row|
            from_val, to_val = parse_bound(row[:bound])
            { name: row[:name], from: from_val, to: to_val }
          end
          log.info "PartitionManager list_partitions table=#{table} count=#{partitions.size}"
          partitions
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :list_partitions, table: table)
          []
        end

        private

        def postgres?
          Legion::Data::Connection.adapter == :postgres
        end

        def partition_name(table, date)
          "#{table}_y#{date.strftime('%Y')}m#{date.strftime('%m')}"
        end

        def advance_months(date, months)
          year  = date.year
          month = date.month + months
          while month > 12
            month -= 12
            year  += 1
          end
          while month < 1
            month += 12
            year  -= 1
          end
          Date.new(year, month, 1)
        end

        def partition_names_for(table)
          sql = <<~SQL
            SELECT c.relname AS name
            FROM   pg_inherits i
            JOIN   pg_class    p ON p.oid = i.inhparent
            JOIN   pg_class    c ON c.oid = i.inhrelid
            WHERE  p.relname = '#{table}'
          SQL

          Legion::Data.connection.fetch(sql).map { |row| row[:name] }
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :partition_names_for, table: table)
          []
        end

        def parse_partition_date(partition_name)
          match = partition_name.match(/y(\d{4})m(\d{2})$/)
          return nil unless match

          Date.new(match[1].to_i, match[2].to_i, 1)
        end

        def parse_bound(expr)
          return [nil, nil] unless expr

          matches = expr.scan(/'([^']+)'/)
          from_val = matches[0]&.first
          to_val   = matches[1]&.first
          [from_val, to_val]
        end
      end
    end
  end
end
