# frozen_string_literal: true

# Placeholder: 070 is reserved for WS-03 (lex-audit-resume).
# This no-op migration keeps the IntegerMigrator sequence intact until that PR merges.
Sequel.migration do
  up do
    # no-op
  end

  down do
    # no-op
  end
end
