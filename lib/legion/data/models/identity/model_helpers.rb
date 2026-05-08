# frozen_string_literal: true

require 'securerandom'

module Legion
  module Data
    module Model
      class Identity
        module ModelHelpers
          def self.included(model)
            model.extend(ClassMethods)
          end

          module ClassMethods
            def lookup(value)
              lookup_by_columns(value, lookup_columns)
            end

            def lookup_by_columns(value, lookup_columns)
              normalized = normalize_lookup_value(value)
              return if normalized.nil?

              lookup_columns.each do |column|
                next unless columns.include?(column)

                query_value = lookup_query_value(column, normalized)
                next if query_value == :skip

                record = where(column => query_value).first
                return record if record
              end

              nil
            end

            private

            def lookup_columns
              %i[id uuid name]
            end

            def normalize_lookup_value(value)
              normalized = value.is_a?(String) ? value.strip : value
              return if normalized.respond_to?(:empty?) && normalized.empty?

              normalized
            end

            def lookup_query_value(column, value)
              case column
              when :id
                return value.to_i if integer_lookup_value?(value)
                return value.to_s if uuid_lookup_value?(value) && !columns.include?(:uuid)

                :skip
              when :uuid
                uuid_lookup_value?(value) ? value.to_s : :skip
              else
                value.to_s
              end
            end

            def integer_lookup_value?(value)
              value.is_a?(Integer) || value.to_s.match?(/\A\d+\z/)
            end

            def uuid_lookup_value?(value)
              value.to_s.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
            end
          end

          def before_create
            self[:uuid] ||= SecureRandom.uuid if self.class.columns.include?(:uuid)
            super
          end
        end
      end
    end
  end
end
