module Render
  module Errors
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

    class Schema
      class NotFound < StandardError
        attr_accessor :title

        def initialize(title)
          self.title = title
        end

        def to_s
          "Schema with title #{title} is not loaded"
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
