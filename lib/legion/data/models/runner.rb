# frozen_string_literal: true

require_relative 'function'
module Legion
  module Data
    module Model
      class Runner < Sequel::Model
        one_to_many :functions
        many_to_one :extension
      end
    end
  end
end
