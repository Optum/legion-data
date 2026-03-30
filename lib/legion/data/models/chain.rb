# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Chain < Sequel::Model
        one_to_many :relationships, key: :chain_id
      end
    end
  end
end
