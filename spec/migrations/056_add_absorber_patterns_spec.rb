# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 056: add absorber_patterns table' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 56)
  end

  it 'creates the absorber_patterns table' do
    expect(db.table_exists?(:absorber_patterns)).to be true
  end

  describe 'columns' do
    let(:columns) { db.schema(:absorber_patterns).map(&:first) }

    it 'has all required columns' do
      expect(columns).to include(
        :id, :function_id, :pattern_type, :pattern,
        :priority, :active, :tenant_id, :created_at, :updated_at
      )
    end

    it 'pattern_type defaults to url' do
      col = db.schema(:absorber_patterns).find { |c| c.first == :pattern_type }
      expect(col.last[:ruby_default]).to eq('url')
    end

    it 'priority defaults to 0' do
      col = db.schema(:absorber_patterns).find { |c| c.first == :priority }
      expect(col.last[:ruby_default]).to eq(0)
    end

    it 'active defaults to true' do
      col = db.schema(:absorber_patterns).find { |c| c.first == :active }
      expect(col.last[:ruby_default]).to eq(true)
    end

    it 'function_id is not nullable' do
      col = db.schema(:absorber_patterns).find { |c| c.first == :function_id }
      expect(col.last[:allow_null]).to be false
    end

    it 'tenant_id is nullable' do
      col = db.schema(:absorber_patterns).find { |c| c.first == :tenant_id }
      expect(col.last[:allow_null]).to be true
    end
  end

  describe 'indexes' do
    it 'has index on function_id' do
      expect(db.indexes(:absorber_patterns).values.any? { |i| i[:columns].include?(:function_id) }).to be true
    end

    it 'has index on pattern_type' do
      expect(db.indexes(:absorber_patterns)).to have_key(:idx_absorber_patterns_pattern_type)
    end

    it 'has index on active' do
      expect(db.indexes(:absorber_patterns)).to have_key(:idx_absorber_patterns_active)
    end

    it 'has index on tenant_id' do
      expect(db.indexes(:absorber_patterns)).to have_key(:idx_absorber_patterns_tenant_id)
    end

    it 'has composite index on pattern_type and active' do
      expect(db.indexes(:absorber_patterns)).to have_key(:idx_absorber_patterns_type_active)
    end
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 56)
    end.not_to raise_error
  end
end
