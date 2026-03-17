# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/archival/policy'

RSpec.describe Legion::Data::Archival::Policy do
  describe '.new' do
    it 'uses defaults' do
      policy = described_class.new
      expect(policy.warm_after_days).to eq(7)
      expect(policy.cold_after_days).to eq(90)
      expect(policy.batch_size).to eq(1000)
    end

    it 'accepts overrides' do
      policy = described_class.new(warm_after_days: 14, cold_after_days: 180)
      expect(policy.warm_after_days).to eq(14)
      expect(policy.cold_after_days).to eq(180)
    end
  end

  describe '#warm_cutoff' do
    it 'returns time warm_after_days ago' do
      policy = described_class.new(warm_after_days: 7)
      expect(policy.warm_cutoff).to be_within(2).of(Time.now - 604_800)
    end
  end

  describe '#cold_cutoff' do
    it 'returns time cold_after_days ago' do
      policy = described_class.new(cold_after_days: 90)
      expect(policy.cold_cutoff).to be_within(2).of(Time.now - (90 * 86_400))
    end
  end
end
