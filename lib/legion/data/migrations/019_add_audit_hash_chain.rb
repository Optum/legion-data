# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    unless cols.include?(:record_hash)
      alter_table(:audit_log) { add_column :record_hash, String, size: 255 }
      add_index :audit_log, :record_hash
    end

    unless cols.include?(:previous_hash)
      alter_table(:audit_log) { add_column :previous_hash, String, size: 255 }
    end

    unless cols.include?(:retention_tier)
      alter_table(:audit_log) { add_column :retention_tier, String, size: 10, default: 'hot' }
      add_index :audit_log, :retention_tier
    end
  end

  down do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    if cols.include?(:record_hash)
      drop_index :audit_log, :record_hash, if_exists: true
      alter_table(:audit_log) { drop_column :record_hash }
    end

    if cols.include?(:previous_hash)
      alter_table(:audit_log) { drop_column :previous_hash }
    end

    if cols.include?(:retention_tier)
      drop_index :audit_log, :retention_tier, if_exists: true
      alter_table(:audit_log) { drop_column :retention_tier }
    end
  end
end
