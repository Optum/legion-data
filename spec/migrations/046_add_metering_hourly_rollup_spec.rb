# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 046: add metering_hourly_rollup table' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 46)
  end

  it 'creates the metering_hourly_rollup table' do
    expect(db.table_exists?(:metering_hourly_rollup)).to be true
  end

  it 'has all required columns' do
    columns = db.schema(:metering_hourly_rollup).map(&:first)
    expect(columns).to include(
      :id, :worker_id, :provider, :model_id, :hour,
      :total_input_tokens, :total_output_tokens, :total_thinking_tokens,
      :total_calls, :total_cost_usd, :avg_latency_ms,
      :tenant_id, :created_at
    )
  end

  it 'total_input_tokens defaults to 0' do
    col = db.schema(:metering_hourly_rollup).find { |c| c.first == :total_input_tokens }
    expect(col.last[:ruby_default]).to eq(0)
  end

  it 'total_cost_usd defaults to 0.0' do
    col = db.schema(:metering_hourly_rollup).find { |c| c.first == :total_cost_usd }
    expect(col.last[:ruby_default]).to eq(0.0)
  end

  it 'has a unique index on [worker_id, provider, model_id, hour]' do
    indexes = db.indexes(:metering_hourly_rollup)
    expected_cols = %i[hour model_id provider worker_id].sort
    unique_quad = indexes.values.find do |i|
      i[:unique] && i[:columns].sort == expected_cols
    end
    expect(unique_quad).not_to be_nil
  end

  it 'has an index on hour' do
    indexes = db.indexes(:metering_hourly_rollup)
    indexed_columns = indexes.values.flat_map { |i| i[:columns] }
    expect(indexed_columns).to include(:hour)
  end

  it 'has an index on tenant_id' do
    indexes = db.indexes(:metering_hourly_rollup)
    indexed_columns = indexes.values.flat_map { |i| i[:columns] }
    expect(indexed_columns).to include(:tenant_id)
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 46)
    end.not_to raise_error
  end
end
