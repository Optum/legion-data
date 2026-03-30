# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:audit_log)

    cols    = schema(:audit_log).map(&:first)
    indexes = db.indexes(:audit_log)

    alter_table(:audit_log) { add_column :record_hash, String, size: 255 } unless cols.include?(:record_hash)

    add_index :audit_log, :record_hash unless indexes.key?(:audit_log_record_hash_index)

    alter_table(:audit_log) { add_column :previous_hash, String, size: 255 } unless cols.include?(:previous_hash)

    alter_table(:audit_log) { add_column :retention_tier, String, size: 10, default: 'hot' } unless cols.include?(:retention_tier)

    add_index :audit_log, :retention_tier unless indexes.key?(:audit_log_retention_tier_index)
  end

  down do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    if cols.include?(:record_hash)
      drop_index :audit_log, :record_hash, if_exists: true
      alter_table(:audit_log) { drop_column :record_hash }
    end

    alter_table(:audit_log) { drop_column :previous_hash } if cols.include?(:previous_hash)

    if cols.include?(:retention_tier)
      drop_index :audit_log, :retention_tier, if_exists: true
      alter_table(:audit_log) { drop_column :retention_tier }
    end
  end
end
