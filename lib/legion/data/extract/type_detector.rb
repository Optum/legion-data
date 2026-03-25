# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module TypeDetector
        EXTENSION_MAP = {
          '.pdf'      => :pdf,
          '.docx'     => :docx,
          '.pptx'     => :pptx,
          '.xlsx'     => :xlsx,
          '.xls'      => :xlsx,
          '.md'       => :markdown,
          '.markdown' => :markdown,
          '.txt'      => :text,
          '.csv'      => :csv,
          '.json'     => :json,
          '.jsonl'    => :jsonl,
          '.html'     => :html,
          '.htm'      => :html
        }.freeze

        module_function

        def detect(source)
          return detect_from_path(source) if source.is_a?(String) && File.exist?(source)
          return detect_from_io(source) if source.respond_to?(:path)

          nil
        end

        def detect_from_path(path)
          ext = File.extname(path).downcase
          EXTENSION_MAP[ext]
        end

        def detect_from_io(io)
          return nil unless io.respond_to?(:path) && io.path

          detect_from_path(io.path)
        end
      end
    end
  end
end
