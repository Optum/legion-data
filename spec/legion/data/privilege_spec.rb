# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Legion::Data privilege checks' do
  before do
    Legion::Data.instance_variable_set(:@write_privileges, nil)
    Legion::Data.instance_variable_set(:@read_privileges, nil)
  end

  describe '.can_write?' do
    context 'when not connected' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: false })
      end

      it 'returns false' do
        expect(Legion::Data.can_write?(:apollo_entries)).to be false
      end
    end

    context 'when connected with sqlite adapter' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: true, adapter: 'sqlite' })
      end

      it 'returns true (sqlite has no privilege system)' do
        expect(Legion::Data.can_write?(:apollo_entries)).to be true
      end
    end

    context 'when result is cached' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: true, adapter: 'sqlite' })
        Legion::Data.can_write?(:apollo_entries)
      end

      it 'returns cached value without re-checking' do
        expect(Legion::Data.can_write?(:apollo_entries)).to be true
      end
    end
  end

  describe '.can_read?' do
    context 'when not connected' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: false })
      end

      it 'returns false' do
        expect(Legion::Data.can_read?(:apollo_entries)).to be false
      end
    end

    context 'when connected with sqlite adapter' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: true, adapter: 'sqlite' })
      end

      it 'returns true' do
        expect(Legion::Data.can_read?(:apollo_entries)).to be true
      end
    end
  end

  describe '.connected?' do
    it 'returns true when data is connected' do
      allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: true })
      expect(Legion::Data.connected?).to be true
    end

    it 'returns false when data is not connected' do
      allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: false })
      expect(Legion::Data.connected?).to be false
    end

    it 'returns false on error' do
      allow(Legion::Settings).to receive(:[]).with(:data).and_raise(StandardError)
      expect(Legion::Data.connected?).to be false
    end
  end

  describe '.reset_privileges!' do
    it 'clears cached values' do
      Legion::Data.instance_variable_set(:@write_privileges, { foo: true })
      Legion::Data.reset_privileges!
      expect(Legion::Data.instance_variable_get(:@write_privileges)).to be_nil
    end
  end
end
