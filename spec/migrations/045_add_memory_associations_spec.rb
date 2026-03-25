# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 045: add memory_associations table' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 46)
  end

  it 'creates the memory_associations table' do
    expect(db.table_exists?(:memory_associations)).to be true
  end

  it 'has all required columns' do
    columns = db.schema(:memory_associations).map(&:first)
    expect(columns).to include(:id, :trace_id_a, :trace_id_b, :coactivation_count,
                               :linked, :tenant_id, :created_at, :updated_at)
  end

  it 'coactivation_count defaults to 1' do
    col = db.schema(:memory_associations).find { |c| c.first == :coactivation_count }
    expect(col).not_to be_nil
    expect(col.last[:ruby_default]).to eq(1)
  end

  it 'linked defaults to false' do
    col = db.schema(:memory_associations).find { |c| c.first == :linked }
    expect(col).not_to be_nil
    expect(col.last[:ruby_default]).to be false
  end

  it 'has an index on trace_id_a' do
    indexes = db.indexes(:memory_associations)
    indexed_columns = indexes.values.flat_map { |i| i[:columns] }
    expect(indexed_columns).to include(:trace_id_a)
  end

  it 'has an index on trace_id_b' do
    indexes = db.indexes(:memory_associations)
    indexed_columns = indexes.values.flat_map { |i| i[:columns] }
    expect(indexed_columns).to include(:trace_id_b)
  end

  it 'has an index on tenant_id' do
    indexes = db.indexes(:memory_associations)
    indexed_columns = indexes.values.flat_map { |i| i[:columns] }
    expect(indexed_columns).to include(:tenant_id)
  end

  it 'has a unique constraint on [trace_id_a, trace_id_b]' do
    indexes = db.indexes(:memory_associations)
    unique_pair = indexes.values.find do |i|
      i[:unique] && i[:columns].sort == %i[trace_id_a trace_id_b].sort
    end
    expect(unique_pair).not_to be_nil
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 45)
    end.not_to raise_error
  end
end
