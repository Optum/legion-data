# frozen_string_literal: true

require 'legion/logging/helper'

require 'sequel/extensions/migration'

module Legion
  module Data
    module Migration
      class << self
        include Legion::Logging::Helper

        def migrate(connection = Legion::Data.connection, path = "#{__dir__}/migrations", **)
          if defined?(Legion::Mode) && Legion::Mode.respond_to?(:current) && !Legion::Mode.infra?
            log.info "Legion::Data::Migration skipped (mode: #{Legion::Mode.current}, requires: infra)"
            return
          end

          Legion::Settings[:data][:migrations][:version] = Sequel::Migrator.run(connection, path, **)
          log.info("Legion::Data::Migration ran successfully to version #{Legion::Settings[:data][:migrations][:version]}")
          Legion::Settings[:data][:migrations][:ran] = true
        rescue Sequel::DatabaseError => e
          handle_exception(e, level: :error, handled: false, operation: :migrate, path: path)
          if e.message.include?('InsufficientPrivilege') || e.message.include?('permission denied')
            raise Sequel::DatabaseError,
                  "#{e.message}\n  Hint: the database user lacks CREATE on schema public " \
                  '(required for PG 15+). Grant via: GRANT CREATE ON SCHEMA public TO <user>;'
          end
          raise
        end
      end
    end
  end
end
