module Render
  class Definition
    @instances = {}

    class << self
      attr_accessor :instances

      def load_from_directory!(directory)
        Dir.glob("#{directory}/**/*.json").each do |definition_file|
          Render.logger.info("Reading #{definition_file} definition")
          definition_string = File.read(definition_file)
          json_definition = JSON.parse(definition_string)
          parsed_definition = Extensions::DottableHash.new(json_definition).recursively_symbolize_keys!
          load!(parsed_definition)
        end
      end

      def load!(definition)
        title = definition.fetch(:universal_title, definition.fetch(:title)).to_sym
        self.instances[title] = definition
      end

      def find(title)
        instances.fetch(title.to_sym)
      rescue KeyError => error
        raise Errors::DefinitionNotFound.new(title)
      end

    end
  end
end
