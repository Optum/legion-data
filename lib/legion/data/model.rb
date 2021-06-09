module Legion
  module Data
    module Models
      class << self
        attr_reader :loaded_models

        def models
          %w[extension function task runner node setting]
        end

        def load
          Legion::Logging.info 'Loading Legion::Data::Models'
          @loaded_models ||= []
          require_sequel_models(models)
          Legion::Settings[:data][:models][:loaded] = true
        end

        def require_sequel_models(files = models)
          # Dir["#{File.dirname(__FILE__)}models/*.rb"].each { |file| puts file }
          files.each { |file| load_sequel_model(file) }
        end

        def load_sequel_model(model)
          Legion::Logging.debug("Trying to load #{model}.rb")
          require_relative "models/#{model}"
          @loaded_models << model
          Legion::Logging.debug("Successfully loaded #{model}")
          model
        rescue LoadError => e
          Legion::Logging.fatal("Failed to load #{model}")
          raise e unless Legion::Settings[:data][:models][:continue_on_fail]
        end
      end
    end
  end
end
