module Render
  module Errors
    class InvalidType < StandardError
      attr_accessor :name

      def initialize(name)
        self.name = name
      end

      def to_s
        "Cannot parse type: #{name}."
      end
    end

    class Generator
      class MalformedAlgorithm < StandardError
        attr_accessor :algorithm

        def initialize(algorithm)
          self.algorithm = algorithm
        end

        def to_s
          "Algorithms must respond to #call, which #{algorithm.inspect} does not."
        end
      end
    end

    class Graph
      class EndpointKeyNotFound < StandardError
        attr_accessor :config_key

        def initialize(config_key)
          self.config_key = config_key
        end

        def to_s
          "No value for key #{config_key} found in config or parental_properties."
        end
      end
    end

    module Definition
      class NoId < StandardError
        attr_accessor :definition

        def initialize(definition)
          self.definition = definition
        end

        def to_s
          "id keyword must be used to differentiate loaded schemas -- none found in: #{definition}"
        end
      end

      class NotFound < StandardError
        attr_accessor :title

        def initialize(title)
          self.title = title
        end

        def to_s
          "Schema with title #{title} is not loaded"
        end
      end
    end

    class Schema
      class InvalidRequire < StandardError
        attr_accessor :schema_definition

        def initialize(schema_definition)
          self.schema_definition = schema_definition
        end

        def to_s
          required_attributes = schema_definition.fetch(:required, [])
          "Could not require the following attributes: #{required_attributes}. This should be an array of attributes for #{schema_definition}"
        end
      end

      class RequestError < StandardError
        attr_accessor :endpoint, :response

        def initialize(endpoint, response)
          self.endpoint = endpoint
          self.response = response
        end

        def to_s
          "Could not reach #{endpoint} because #{response}."
        end
      end

      class InvalidResponse < RequestError
        def to_s
          "Could not parse #{response.inspect} from #{endpoint}"
        end
      end
    end
  end
end
