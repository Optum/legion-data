# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'securerandom'
require 'tmpdir'
require 'zlib'

module Legion
  module Data
    module Archiver
      class UploadError < StandardError; end

      class << self
        def archive_table(table:, retention_days: 90, batch_size: 1000, storage_backend: nil)
          return { skipped: true, reason: 'not_postgres' } unless postgres?

          conn = Legion::Data.connection
          cutoff = Time.now - (retention_days * 86_400)
          now = Time.now.utc

          batches = 0
          total_rows = 0
          paths = []
          batch_n = 0

          loop do
            batch_n += 1
            rows = conn[table].where { created_at < cutoff }.limit(batch_size).all
            break if rows.empty?

            ids = rows.map { |r| r[:id] }
            jsonl = serialize_rows(rows)
            compressed = gzip_compress(jsonl)
            checksum = Digest::SHA256.hexdigest(compressed)
            batch_id = SecureRandom.uuid

            path = upload_batch(
              data:    compressed,
              table:   table.to_s,
              year:    now.year,
              month:   now.month,
              batch_n: batch_n,
              backend: storage_backend
            )

            conn.transaction do
              conn[:archive_manifest].insert(
                batch_id:     batch_id,
                source_table: table.to_s,
                row_count:    rows.size,
                checksum:     checksum,
                storage_path: path,
                archived_at:  now
              )
              conn[table].where(id: ids).delete
            end

            batches += 1
            total_rows += rows.size
            paths << path
          end

          { batches: batches, total_rows: total_rows, paths: paths }
        end

        def upload_batch(data:, table:, year:, month:, batch_n:, backend:)
          case backend
          when :s3
            upload_s3(data: data, table: table, year: year, month: month, batch_n: batch_n)
          when :azure
            upload_azure(data: data, table: table, year: year, month: month, batch_n: batch_n)
          else
            upload_tmpdir(data: data, table: table, year: year, month: month, batch_n: batch_n)
          end
        end

        def manifest_stats
          return {} unless postgres?
          return {} unless Legion::Data.connection.table_exists?(:archive_manifest)

          Legion::Data.connection[:archive_manifest]
                      .group_and_count(:source_table)
                      .select_append(
                        Sequel.function(:sum, :row_count).as(:total_rows),
                        Sequel.function(:min, :archived_at).as(:earliest),
                        Sequel.function(:max, :archived_at).as(:latest)
                      )
                      .all
                      .to_h do |row|
            [row[:source_table], {
              batches:    row[:count],
              total_rows: row[:total_rows].to_i,
              earliest:   row[:earliest],
              latest:     row[:latest]
            }]
          end
        end

        private

        def postgres?
          Legion::Data::Connection.adapter == :postgres
        end

        def serialize_rows(rows)
          rows.map { |row| json_dump(row) }.join("\n")
        end

        def json_dump(obj)
          if defined?(Legion::JSON)
            Legion::JSON.dump(obj)
          else
            ::JSON.generate(obj)
          end
        end

        def gzip_compress(data)
          output = StringIO.new
          output.binmode
          gz = Zlib::GzipWriter.new(output)
          gz.write(data)
          gz.close
          output.string
        end

        def upload_s3(data:, table:, year:, month:, batch_n:)
          raise UploadError, 'S3 backend not available: Legion::Extensions::S3::Runners::Put not defined' unless defined?(Legion::Extensions::S3::Runners::Put)

          key = "legion-archive/#{table}/#{year}/#{month}/batch_#{batch_n}.jsonl.gz"
          Legion::Extensions::S3::Runners::Put.run(key: key, body: data)
          "s3://#{key}"
        rescue UploadError
          raise
        rescue StandardError => e
          raise UploadError, "S3 upload failed: #{e.message}"
        end

        def upload_azure(data:, table:, year:, month:, batch_n:)
          unless defined?(Legion::Extensions::AzureStorage::Runners::Upload)
            raise UploadError, 'Azure backend not available: Legion::Extensions::AzureStorage::Runners::Upload not defined'
          end

          blob_name = "legion-archive/#{table}/#{year}/#{month}/batch_#{batch_n}.jsonl.gz"
          Legion::Extensions::AzureStorage::Runners::Upload.run(blob_name: blob_name, data: data)
          "azure://#{blob_name}"
        rescue UploadError
          raise
        rescue StandardError => e
          raise UploadError, "Azure upload failed: #{e.message}"
        end

        def upload_tmpdir(data:, table:, year:, month:, batch_n:)
          dir = File.join(Dir.tmpdir, 'legion-archive', table.to_s, year.to_s, month.to_s)
          FileUtils.mkdir_p(dir)
          path = File.join(dir, "batch_#{batch_n}.jsonl.gz")
          File.binwrite(path, data)
          "file://#{path}"
        rescue StandardError => e
          raise UploadError, "Tmpdir upload failed: #{e.message}"
        end
      end
    end
  end
end
