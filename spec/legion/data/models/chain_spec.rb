# frozen_string_literal: true

require 'spec_helper'
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Chain do
  subject(:model) { described_class }

  before(:all) do
    Legion::Data::Migration.migrate
  end

  describe '.insert' do
    it 'creates a chain with a name' do
      id = model.insert(name: 'test-workflow')
      expect(id).to be_a(Integer)
      row = model[id]
      expect(row.values[:name]).to eq('test-workflow')
      expect(row.values[:active]).to be true
      row.delete
    end
  end

  describe '#relationships' do
    it 'returns associated relationships' do
      id = model.insert(name: 'chain-with-rels')
      chain = model[id]
      expect(chain.relationships).to be_an(Array)
      chain.delete
    end
  end
end
