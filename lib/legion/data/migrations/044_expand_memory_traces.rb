# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:memory_traces)

    existing = schema(:memory_traces).map(&:first)

    alter_table(:memory_traces) do
      add_column :trace_id, String, size: 36 unless existing.include?(:trace_id)
      add_column :strength, Float, default: 0.5 unless existing.include?(:strength)
      add_column :peak_strength, Float, default: 0.5 unless existing.include?(:peak_strength)
      add_column :base_decay_rate, Float, default: 0.05 unless existing.include?(:base_decay_rate)
      add_column :emotional_valence, Float, default: 0.0 unless existing.include?(:emotional_valence)
      add_column :emotional_intensity, Float, default: 0.0 unless existing.include?(:emotional_intensity)
      add_column :domain_tags, :text unless existing.include?(:domain_tags)
      add_column :origin, String, size: 50 unless existing.include?(:origin)
      add_column :source_agent_id, String, size: 255 unless existing.include?(:source_agent_id)
      add_column :storage_tier, String, size: 10, default: 'warm' unless existing.include?(:storage_tier)
      add_column :last_reinforced, DateTime unless existing.include?(:last_reinforced)
      add_column :last_decayed, DateTime unless existing.include?(:last_decayed)
      add_column :reinforcement_count, Integer, default: 0 unless existing.include?(:reinforcement_count)
      add_column :unresolved, TrueClass, default: false unless existing.include?(:unresolved)
      add_column :consolidation_candidate, TrueClass, default: false unless existing.include?(:consolidation_candidate)
      add_column :parent_trace_id, String, size: 36 unless existing.include?(:parent_trace_id)
      add_column :encryption_key_id, String, size: 255 unless existing.include?(:encryption_key_id)
      add_column :partition_id, String, size: 255 unless existing.include?(:partition_id)
    end

    indexes = begin
      db.indexes(:memory_traces).keys
    rescue StandardError => e
      if defined?(Legion::Data) && Legion::Data.respond_to?(:handle_exception)
        Legion::Data.handle_exception(e, level: :warn, handled: true, operation: :migration_044_indexes)
      end
      []
    end

    add_index :memory_traces, :trace_id, unique: true, name: :idx_memory_traces_trace_id unless existing.include?(:trace_id)

    add_index :memory_traces, :storage_tier, name: :idx_memory_traces_storage_tier unless indexes.include?(:idx_memory_traces_storage_tier)
    add_index :memory_traces, :partition_id, name: :idx_memory_traces_partition_id unless indexes.include?(:idx_memory_traces_partition_id)
    add_index :memory_traces, %i[partition_id trace_type], name: :idx_memory_traces_partition_type unless indexes.include?(:idx_memory_traces_partition_type)
    add_index :memory_traces, :unresolved, name: :idx_memory_traces_unresolved unless indexes.include?(:idx_memory_traces_unresolved)
  end

  down do
    next unless table_exists?(:memory_traces)

    existing = schema(:memory_traces).map(&:first)

    %i[trace_id strength peak_strength base_decay_rate emotional_valence emotional_intensity
       domain_tags origin source_agent_id storage_tier last_reinforced last_decayed
       reinforcement_count unresolved consolidation_candidate parent_trace_id
       encryption_key_id partition_id].each do |col|
      alter_table(:memory_traces) { drop_column col } if existing.include?(col)
    end
  end
end
