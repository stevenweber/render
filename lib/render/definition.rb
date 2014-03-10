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
        self.instances[id(definition, true)] = definition
      end

      def find(title, raise_error = true)
        instances.fetch(title.to_sym)
      rescue KeyError => error
        raise Errors::Definition::NotFound.new(title) if raise_error
      end

      def id(definition, raise_error = false)
        id = definition[:id]

        if id
          id.to_sym
        elsif raise_error
          raise Errors::Definition::NoId.new(definition)
        end
      end

    end
  end
end
