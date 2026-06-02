# frozen_string_literal: true

# This migration previously added schema_version to llm_tool_calls.
# The column was removed from all writers (no code reads/writes it).
# Kept as a no-op so Sequel's integer migrator has a contiguous sequence
# for installations that already ran the original migration 131.

Sequel.migration do
  up do
    # no-op
  end

  down do
    # no-op
  end
end
