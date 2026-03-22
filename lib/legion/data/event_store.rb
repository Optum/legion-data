# frozen_string_literal: true

require 'digest'

module Legion
  module Data
    module EventStore
      GOVERNANCE_EVENT_TYPES = %w[
        consent.granted consent.revoked consent.modified
        extinction.triggered extinction.resolved
        worker.registered worker.retired worker.transferred
        scope.approved scope.violated scope.reconciled
        audit.retention_applied audit.exported
      ].freeze

      class << self
        def append(stream:, type:, data: {}, metadata: {})
          return { error: 'db unavailable' } unless db_ready?

          conn = Legion::Data.connection
          conn.transaction do
            last = conn[:governance_events]
                   .where(stream_id: stream)
                   .order(Sequel.desc(:sequence_number))
                   .first

            seq = (last&.[](:sequence_number) || 0) + 1
            prev_hash = last&.[](:event_hash) || ('0' * 64)

            data_json = Legion::JSON.dump(data)
            metadata_json = Legion::JSON.dump(metadata)
            event_hash = compute_hash(stream, seq, type, data_json, prev_hash)

            conn[:governance_events].insert(
              stream_id:       stream,
              event_type:      type,
              sequence_number: seq,
              data_json:       data_json,
              metadata_json:   metadata_json,
              event_hash:      event_hash,
              previous_hash:   prev_hash,
              created_at:      Time.now
            )

            Legion::Logging.debug "EventStore append: stream=#{stream} type=#{type} seq=#{seq}" if defined?(Legion::Logging)
            { stream: stream, sequence: seq, hash: event_hash }
          end
        end

        def read_stream(stream, since: nil)
          return [] unless db_ready?

          ds = Legion::Data.connection[:governance_events].where(stream_id: stream)
          ds = ds.where { created_at >= since } if since
          ds.order(:sequence_number).all.map { |e| deserialize(e) }
        end

        def read_by_type(type, since: nil, limit: 100)
          return [] unless db_ready?

          ds = Legion::Data.connection[:governance_events].where(event_type: type)
          ds = ds.where { created_at >= since } if since
          ds.order(Sequel.desc(:created_at)).limit(limit).all.map { |e| deserialize(e) }
        end

        def verify_chain(stream)
          return { valid: false, error: 'db unavailable' } unless db_ready?

          events = Legion::Data.connection[:governance_events]
                               .where(stream_id: stream)
                               .order(:sequence_number)
                               .all

          prev_hash = '0' * 64
          events.each do |e|
            expected = compute_hash(stream, e[:sequence_number], e[:event_type], e[:data_json], prev_hash)
            unless e[:event_hash] == expected
              Legion::Logging.warn "EventStore chain broken: stream=#{stream} seq=#{e[:sequence_number]}" if defined?(Legion::Logging)
              return { valid: false, broken_at: e[:sequence_number] }
            end
            unless e[:previous_hash] == prev_hash
              Legion::Logging.warn "EventStore chain broken: stream=#{stream} seq=#{e[:sequence_number]}" if defined?(Legion::Logging)
              return { valid: false, broken_at: e[:sequence_number] }
            end

            prev_hash = e[:event_hash]
          end

          { valid: true, length: events.size }
        end

        private

        def compute_hash(stream, seq, type, data_json, prev_hash)
          Digest::SHA256.hexdigest("#{stream}:#{seq}:#{type}:#{data_json}:#{prev_hash}")
        end

        def deserialize(event)
          {
            id:         event[:id],
            stream:     event[:stream_id],
            type:       event[:event_type],
            sequence:   event[:sequence_number],
            data:       Legion::JSON.load(event[:data_json] || '{}'),
            metadata:   Legion::JSON.load(event[:metadata_json] || '{}'),
            hash:       event[:event_hash],
            created_at: event[:created_at]
          }
        end

        def db_ready?
          defined?(Legion::Data) && Legion::Data.connection&.table_exists?(:governance_events)
        rescue StandardError => e
          Legion::Logging.debug("EventStore#db_ready? check failed: #{e.message}") if defined?(Legion::Logging)
          false
        end
      end
    end
  end
end
