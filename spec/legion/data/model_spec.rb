require 'spec_helper'

RSpec.describe Legion::Data::Models do
  after(:each) do
    Legion::Data::Connection.shutdown
  end

  it 'can load' do
    expect { Legion::Data::Models.load }.not_to raise_exception
    expect(Legion::Settings[:data][:models][:loaded]).to eq true
  end

  it '.require_sequel_models' do
    expect(Legion::Data::Models.require_sequel_models).to be_a Array
    expect(Legion::Data::Models.require_sequel_models([])).to eq []
    expect { Legion::Data::Models.require_sequel_models(['bad_model']) }.to raise_exception(LoadError)
  end

  it '.load_sequel_model' do
    expect(Legion::Data::Models.load_sequel_model('task')).to eq 'task'
    expect { Legion::Data::Models.load_sequel_model('bad_model') }.to raise_exception LoadError
  end

  it '.models' do
    expect(Legion::Data::Models.models).to be_a Array
    expect(Legion::Data::Models.models).to include 'task'
    expect(Legion::Data::Models.models).to include 'runner'
    expect(Legion::Data::Models.models).to include 'extension'
    expect(Legion::Data::Models.models).to include 'node'
    expect(Legion::Data::Models.models).to include 'setting'
    expect(Legion::Data::Models.models).to include 'function'
    expect(Legion::Data::Models.models).not_to include 'bad_model'
  end
end
