module Render
  class Definition
    @instances = {}

    class << self
      attr_accessor :instances

      def load_from_directory!(directory)
        Dir.glob("#{directory}/**/*.json").each do |definition_file|
          Render.logger.info("Reading #{definition_file} definition")
          definition_string = File.read(definition_file)
          parsed_definition = JSON.parse(definition_string, { symbolize_names: true })
          load!(parsed_definition)
        end
      end

      def load!(definition)
        self.instances.merge!({ parse_id!(definition) => definition })
      end

      def find(id, raise_error = true)
        instances.fetch(id)
      rescue KeyError => error
        raise Errors::Definition::NotFound.new(id) if raise_error
      end

      def parse_id!(definition)
        parse_id(definition) || (raise Errors::Definition::NoId.new(definition))
      end

      def parse_id(definition)
        definition[:id]
      end

    end
  end
end
