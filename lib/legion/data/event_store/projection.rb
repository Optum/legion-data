# frozen_string_literal: true

module Legion
  module Data
    module EventStore
      class Projection
        attr_reader :state

        def initialize
          @state = {}
        end

        def apply(_event)
          raise NotImplementedError, "#{self.class} must implement #apply"
        end

        def self.build_from(stream, since: nil)
          projection = new
          events = EventStore.read_stream(stream, since: since)
          events.each { |e| projection.apply(e) }
          projection
        end
      end

      class ConsentState < Projection
        def apply(event)
          scope = event.dig(:data, :scope)
          return unless scope

          case event[:type]
          when 'consent.granted', 'consent.modified'
            @state[scope] = event.dig(:data, :tier)
          when 'consent.revoked'
            @state.delete(scope)
          end
        end
      end

      class GovernanceTimeline < Projection
        def initialize
          super
          @state = []
        end

        def apply(event)
          @state << {
            type:   event[:type],
            stream: event[:stream],
            at:     event[:created_at],
            data:   event[:data]
          }
        end
      end
    end
  end
end
