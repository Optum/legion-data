# frozen_string_literal: true

# Migration 115 had a bug: it guarded the up block on the :definition column
# (added by migration 055) instead of :runtime_caller_class. This means on
# deployments where :definition existed but :runtime_caller_class did not,
# the columns were added correctly. But the guard was checking the wrong
# thing, and the down block has no guard at all.
#
# This migration ensures the columns exist on any deployment that might have
# skipped them due to the 115 bug.

Sequel.migration do
  up do
    if table_exists?(:llm_message_inference_requests)
      cols = schema(:llm_message_inference_requests).map(&:first)
      unless cols.include?(:runtime_caller_class) && cols.include?(:runtime_caller_client)
        alter_table(:llm_message_inference_requests) do
          add_column :runtime_caller_class, String, size: 255, null: true, index: true unless cols.include?(:runtime_caller_class)
          add_column :runtime_caller_client, String, size: 255, null: true unless cols.include?(:runtime_caller_client)
        end
      end
    end
  end

  down do
    if table_exists?(:llm_message_inference_requests)
      cols = schema(:llm_message_inference_requests).map(&:first)
      if cols.include?(:runtime_caller_class) || cols.include?(:runtime_caller_client)
        alter_table(:llm_message_inference_requests) do
          drop_column :runtime_caller_client if cols.include?(:runtime_caller_client)
          drop_column :runtime_caller_class if cols.include?(:runtime_caller_class)
        end
      end
    end
  end
end
