# frozen_string_literal: true

RSpec.describe Legion::Data::Rls do
  describe '.rls_enabled?' do
    it 'returns false for SQLite adapter' do
      expect(described_class.rls_enabled?).to be(false)
    end
  end

  describe '.assign_tenant' do
    it 'is a no-op on non-postgres' do
      expect { described_class.assign_tenant('test') }.not_to raise_error
    end
  end

  describe '.current_tenant' do
    it 'returns nil on non-postgres' do
      expect(described_class.current_tenant).to be_nil
    end
  end

  describe '.reset_tenant' do
    it 'is a no-op on non-postgres' do
      expect { described_class.reset_tenant }.not_to raise_error
    end
  end

  describe '.with_tenant' do
    it 'yields the block and returns its value' do
      result = described_class.with_tenant('test') { 42 }
      expect(result).to eq(42)
    end
  end

  describe '::RLS_TABLES' do
    it 'lists all tables with tenant_id' do
      expect(described_class::RLS_TABLES).to include(:tasks, :extensions, :memory_traces)
    end

    it 'contains 10 tables' do
      expect(described_class::RLS_TABLES.size).to eq(10)
    end
  end
end
