# frozen_string_literal: true

require 'digest'

module Legion
  module Data
    module AuditRecord
      GENESIS_HASH = ('0' * 64).freeze

      class << self
        # Append a new record to the named chain. Returns the persisted record hash
        # on success, or an error hash when the database is unavailable.
        #
        # @param chain_id     [String]  chain identifier (scopes the sequence)
        # @param content_type [String]  caller-defined type label
        # @param content_hash [String]  SHA-256 hex digest of the content being recorded
        # @param metadata     [Hash]    optional structured context (serialised to JSON)
        # @param sign         [Boolean] when true, attempt signing via legion-crypt
        def append(chain_id:, content_type:, content_hash:, metadata: {}, sign: false)
          return { error: 'db unavailable' } unless db_ready?

          conn = Legion::Data.connection
          conn.transaction do
            parent_hash = latest_chain_hash(conn, chain_id)
            ts          = Time.now
            ch          = compute_chain_hash(parent_hash, content_hash, ts, content_type)
            sig         = sign ? sign_record(ch) : nil
            meta_json   = metadata.empty? ? nil : Legion::JSON.dump(metadata)

            id = conn[:audit_records].insert(
              chain_id:     chain_id,
              content_type: content_type,
              content_hash: content_hash,
              parent_hash:  parent_hash,
              chain_hash:   ch,
              signature:    sig,
              metadata:     meta_json,
              created_at:   ts
            )

            Legion::Logging.debug "AuditRecord append: chain=#{chain_id} type=#{content_type} id=#{id}" if defined?(Legion::Logging)
            { id: id, chain_id: chain_id, chain_hash: ch, parent_hash: parent_hash }
          end
        end

        # Walk all records in the chain ordered by creation time and verify that
        # each record's stored chain_hash matches a freshly computed one.
        #
        # @param chain_id [String]
        # @return [Hash] { valid: Boolean, length: Integer, broken_at: Integer? }
        def verify(chain_id:)
          return { valid: false, error: 'db unavailable' } unless db_ready?

          records = Legion::Data.connection[:audit_records]
                                .where(chain_id: chain_id)
                                .order(:created_at, :id)
                                .all

          prev_hash = GENESIS_HASH
          records.each do |r|
            unless r[:parent_hash] == prev_hash
              Legion::Logging.warn "AuditRecord chain broken: chain=#{chain_id} id=#{r[:id]}" if defined?(Legion::Logging)
              return { valid: false, broken_at: r[:id], reason: :parent_mismatch }
            end

            expected = compute_chain_hash(prev_hash, r[:content_hash], r[:created_at], r[:content_type])
            unless r[:chain_hash] == expected
              Legion::Logging.warn "AuditRecord hash mismatch: chain=#{chain_id} id=#{r[:id]}" if defined?(Legion::Logging)
              return { valid: false, broken_at: r[:id], reason: :hash_mismatch }
            end

            prev_hash = r[:chain_hash]
          end

          { valid: true, length: records.size }
        end

        # Return all records for a chain as deserialised hashes.
        #
        # @param chain_id [String]
        # @param since    [Time, nil] optional lower bound on created_at
        # @param limit    [Integer]
        def walk(chain_id:, since: nil, limit: 1000)
          return [] unless db_ready?

          ds = Legion::Data.connection[:audit_records].where(chain_id: chain_id)
          ds = ds.where { created_at >= since } if since
          ds.order(:created_at, :id).limit(limit).all.map { |r| deserialize(r) }
        end

        # Return records filtered by content_type across all chains.
        #
        # @param content_type [String]
        # @param since        [Time, nil]
        # @param limit        [Integer]
        def query_by_type(content_type:, since: nil, limit: 100)
          return [] unless db_ready?

          ds = Legion::Data.connection[:audit_records].where(content_type: content_type)
          ds = ds.where { created_at >= since } if since
          ds.order(Sequel.desc(:created_at)).limit(limit).all.map { |r| deserialize(r) }
        end

        # SHA-256 of "parent_hash:content_hash:unix_ts_ns:content_type".
        #
        # The timestamp is normalised to nanoseconds-since-epoch so the hash is
        # independent of time zone, string formatting, and database type.
        # Exposed as a public method so callers can independently verify a hash
        # without querying the database.
        def compute_chain_hash(parent_hash, content_hash, timestamp, content_type)
          ts_ns = normalise_timestamp_ns(timestamp)
          Digest::SHA256.hexdigest("#{parent_hash}:#{content_hash}:#{ts_ns}:#{content_type}")
        end

        private

        # Normalise a timestamp to integer nanoseconds-since-epoch regardless of
        # whether the database returned a Time, DateTime, or String.
        def normalise_timestamp_ns(timestamp)
          case timestamp
          when ::Time
            (timestamp.to_r * 1_000_000_000).to_i
          when ::DateTime
            (timestamp.to_time.to_r * 1_000_000_000).to_i
          else
            ts = ::Time.parse(timestamp.to_s)
            (ts.to_r * 1_000_000_000).to_i
          end
        end

        def latest_chain_hash(conn, chain_id)
          last = conn[:audit_records]
                 .select(:chain_hash)
                 .where(chain_id: chain_id)
                 .order(Sequel.desc(:created_at), Sequel.desc(:id))
                 .first
          last ? last[:chain_hash] : GENESIS_HASH
        end

        def sign_record(chain_hash)
          return nil unless defined?(Legion::Crypt) && Legion::Crypt.respond_to?(:sign)

          Legion::Crypt.sign(chain_hash)
        rescue StandardError => e
          Legion::Logging.warn "AuditRecord signing failed: #{e.message}" if defined?(Legion::Logging)
          nil
        end

        def deserialize(row)
          {
            id:           row[:id],
            chain_id:     row[:chain_id],
            content_type: row[:content_type],
            content_hash: row[:content_hash],
            parent_hash:  row[:parent_hash],
            chain_hash:   row[:chain_hash],
            signature:    row[:signature],
            metadata:     row[:metadata] ? Legion::JSON.load(row[:metadata]) : {},
            created_at:   row[:created_at]
          }
        end

        def db_ready?
          defined?(Legion::Data) && Legion::Data.connection&.table_exists?(:audit_records)
        rescue StandardError => e
          Legion::Logging.debug "AuditRecord#db_ready? check failed: #{e.message}" if defined?(Legion::Logging)
          false
        end
      end
    end
  end
end
