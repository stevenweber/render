# Render allows one to define object Graphs with Schema/endpoint information.
# Once defined and constructed, a Graph can be built at once that will:
#  - Query its endpoint to construct a hash for its Schema
#  - Add nested Graphs by interpreting/sending data they need

require "extensions/enumerable"
require "extensions/boolean"
require "extensions/hash"

require "render/version"
require "render/graph"
require "render/generator"
require "logger"

module Render
  @live = true
  @schemas = {}
  @generators = []
  @logger = ::Logger.new($stdout)

  class << self
    attr_accessor :live, :schemas, :generators, :logger

    def load_schemas!(directory)
      Dir.glob("#{directory}/**/*.json").each do |schema_file|
        logger.info("Reading #{schema_file} schema")
        parsed_schema = parse_schema(File.read(schema_file))
        schema_title = parsed_schema[:title].to_sym
        # TODO Throw an error in the event of conflicts?
        self.schemas[schema_title] = parsed_schema
      end
    end

    def parse_schema(json)
      JSON.parse(json).recursive_symbolize_keys!
    end

    def parse_type(type)
      if type.is_a?(String)
        return UUID if type == "uuid"
        return Boolean if type == "boolean"
        return Float if type == "number"
        Object.const_get(type.capitalize) # TODO better type parsing
      else
        type
      end
    end
  end

end
