# frozen_string_literal: true

module Legion
  module Data
    module Model
      class DigitalWorker < Sequel::Model
        one_to_many :tasks, key: :worker_id, primary_key: :worker_id

        LIFECYCLE_STATES = %w[bootstrap active paused retired terminated].freeze
        CONSENT_TIERS    = %w[supervised consult notify autonomous].freeze
        RISK_TIERS       = %w[low medium high critical].freeze
        HEALTH_STATUSES  = %w[online offline unknown].freeze

        def validate
          super
          errors.add(:lifecycle_state, 'invalid') unless LIFECYCLE_STATES.include?(lifecycle_state)
          errors.add(:consent_tier, 'invalid')    unless CONSENT_TIERS.include?(consent_tier)
          errors.add(:risk_tier, 'invalid')        if risk_tier && !RISK_TIERS.include?(risk_tier)
          errors.add(:health_status, 'invalid')    if health_status && !HEALTH_STATUSES.include?(health_status)
        end

        def active?
          lifecycle_state == 'active'
        end

        def terminated?
          lifecycle_state == 'terminated'
        end

        def paused?
          lifecycle_state == 'paused'
        end

        def online?
          health_status == 'online'
        end

        def offline?
          health_status == 'offline'
        end
      end
    end
  end
end
