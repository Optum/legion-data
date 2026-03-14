# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:extensions_registry) do
      primary_key :id
      String :name, null: false, unique: true, size: 100
      String :module_name, null: false, size: 100
      String :category, null: false, size: 50, default: 'cognition'
      String :description, text: true
      String :cognitive_concept, text: true
      String :metaphor_description, text: true
      Integer :build_batch
      DateTime :build_date
      String :status, null: false, size: 20, default: 'active'
      Integer :spec_count, default: 0
      Integer :spec_pass_count, default: 0
      String :wired_phase, size: 100
      Float :health_score, default: 1.0
      Integer :invocation_count, default: 0
      DateTime :last_invoked_at
      DateTime :created_at
      DateTime :updated_at

      index :category
      index :status
      index :health_score
    end
  end
end
