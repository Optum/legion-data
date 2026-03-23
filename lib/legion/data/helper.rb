# frozen_string_literal: true

module Legion
  module Data
    module Helper
      def data_path
        @data_path ||= "#{full_path}/data"
      end

      def data_class
        @data_class ||= lex_class::Data
      end

      def models_class
        @models_class ||= data_class::Model
      end

      def data_connected?
        defined?(Legion::Settings) && Legion::Settings[:data][:connected]
      end

      def data_connection
        Legion::Data::Connection.sequel
      end

      def local_data_connected?
        Legion::Data::Local.connected?
      end

      def local_data_connection
        Legion::Data::Local.connection
      end

      def local_data_model(table_name)
        Legion::Data::Local.model(table_name)
      end
    end
  end
end
