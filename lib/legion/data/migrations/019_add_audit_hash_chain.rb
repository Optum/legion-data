# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:audit_log)

    cols    = schema(:audit_log).map(&:first)
    idxs    = indexes(:audit_log)

    # record_hash exists from migration 017 at size 64; widen to 255 if needed.
    if cols.include?(:record_hash)
      set_column_type :audit_log, :record_hash, String, size: 255
    else
      alter_table(:audit_log) { add_column :record_hash, String, size: 255 }
    end

    add_index :audit_log, :record_hash unless idxs.key?(:audit_log_record_hash_index)

    # Rename prev_hash (introduced in migration 017) to previous_hash for clarity.
    if cols.include?(:prev_hash) && !cols.include?(:previous_hash)
      rename_column :audit_log, :prev_hash, :previous_hash
    elsif !cols.include?(:previous_hash)
      alter_table(:audit_log) { add_column :previous_hash, String, size: 255 }
    end

    alter_table(:audit_log) { add_column :retention_tier, String, size: 10, default: 'hot' } unless cols.include?(:retention_tier)

    add_index :audit_log, :retention_tier unless idxs.key?(:audit_log_retention_tier_index)
  end

  down do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    drop_index :audit_log, :record_hash, if_exists: true

    # Rename previous_hash back to prev_hash (reverse of the up rename).
    if cols.include?(:previous_hash) && !cols.include?(:prev_hash)
      rename_column :audit_log, :previous_hash, :prev_hash
    elsif cols.include?(:previous_hash)
      alter_table(:audit_log) { drop_column :previous_hash }
    end

    if cols.include?(:retention_tier)
      drop_index :audit_log, :retention_tier, if_exists: true
      alter_table(:audit_log) { drop_column :retention_tier }
    end
  end
end
