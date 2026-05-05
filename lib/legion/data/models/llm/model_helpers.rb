# frozen_string_literal: true

require 'securerandom'

module Legion
  module Data
    module Model
      module LLM
        module ModelHelpers
          def before_create
            self[:uuid] ||= SecureRandom.uuid if columns.include?(:uuid)
            super
          end
        end
      end
    end
  end
end
