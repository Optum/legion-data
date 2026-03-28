# frozen_string_literal: true

Sequel.migration do
  change do
    add_column :functions, :remote_invocable, TrueClass, default: true
  end
end
