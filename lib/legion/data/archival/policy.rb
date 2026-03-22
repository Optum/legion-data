# frozen_string_literal: true

module Legion
  module Data
    module Archival
      class Policy
        DEFAULTS = {
          warm_after_days: 7,
          cold_after_days: 90,
          batch_size:      1000,
          tables:          %w[tasks metering_records].freeze
        }.freeze

        attr_reader :warm_after_days, :cold_after_days, :batch_size, :tables

        def initialize(**opts)
          config = DEFAULTS.merge(opts)
          @warm_after_days = config[:warm_after_days]
          @cold_after_days = config[:cold_after_days]
          @batch_size = config[:batch_size]
          @tables = config[:tables]
        end

        def warm_cutoff
          Time.now - (warm_after_days * 86_400)
        end

        def cold_cutoff
          Time.now - (cold_after_days * 86_400)
        end

        def self.from_settings
          return new unless defined?(Legion::Settings)

          data_settings = Legion::Settings[:data]
          archival = data_settings.is_a?(Hash) ? data_settings[:archival] : nil
          return new unless archival.is_a?(Hash)

          new(**archival.slice(:warm_after_days, :cold_after_days, :batch_size, :tables))
        rescue StandardError => e
          Legion::Logging.warn("Policy.from_settings failed: #{e.message}") if defined?(Legion::Logging)
          new
        end
      end
    end
  end
end
