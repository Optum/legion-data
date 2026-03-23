# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Data::Helper do
  describe '#data_connected?' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper
      end
    end
    let(:instance) { test_class.new }

    it 'returns true when data is connected' do
      allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: true })
      expect(instance.data_connected?).to be true
    end

    it 'returns false when data is not connected' do
      allow(Legion::Settings).to receive(:[]).with(:data).and_return({ connected: false })
      expect(instance.data_connected?).to be false
    end
  end

  describe '#data_connection' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper
      end
    end
    let(:instance) { test_class.new }

    it 'delegates to Legion::Data::Connection.sequel' do
      expect(instance.data_connection).to eq(Legion::Data::Connection.sequel)
    end
  end

  describe '#data_path' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper

        def full_path
          '/opt/legion/extensions/lex-test'
        end
      end
    end
    let(:instance) { test_class.new }

    it 'returns the data subdirectory path' do
      expect(instance.data_path).to eq('/opt/legion/extensions/lex-test/data')
    end

    it 'memoizes the result' do
      first = instance.data_path
      expect(instance.data_path).to equal(first)
    end
  end

  describe '#local_data_connected?' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper
      end
    end
    let(:instance) { test_class.new }

    it 'delegates to Legion::Data::Local.connected?' do
      allow(Legion::Data::Local).to receive(:connected?).and_return(true)
      expect(instance.local_data_connected?).to be true
    end
  end

  describe '#local_data_connection' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper
      end
    end
    let(:instance) { test_class.new }

    it 'delegates to Legion::Data::Local.connection' do
      conn = double('local_connection')
      allow(Legion::Data::Local).to receive(:connection).and_return(conn)
      expect(instance.local_data_connection).to eq(conn)
    end
  end

  describe '#local_data_model' do
    let(:test_class) do
      Class.new do
        include Legion::Data::Helper
      end
    end
    let(:instance) { test_class.new }

    it 'delegates to Legion::Data::Local.model with table name' do
      model = double('model')
      allow(Legion::Data::Local).to receive(:model).with(:tasks).and_return(model)
      expect(instance.local_data_model(:tasks)).to eq(model)
    end
  end
end
