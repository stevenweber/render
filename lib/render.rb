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
require "date"

module Render
  @live = true
  @definitions = {}
  @generators = []
  @logger = ::Logger.new($stdout)
  @threading = true

  class << self
    attr_accessor :live,
      :definitions,
      :generators,
      :logger,
      :threading

    def threading?
      threading == true
    end

    def load_definitions!(directory)
      Dir.glob("#{directory}/**/*.json").each do |definition_file|
        logger.info("Reading #{definition_file} definition")
        definition_string = File.read(definition_file)
        parsed_definition = JSON.parse(definition_string).recursive_symbolize_keys!
        load_definition!(parsed_definition)
      end
    end

    def load_definition!(definition)
      title = definition.fetch(:universal_title, definition.fetch(:title)).to_sym
      self.definitions[title] = definition
    end

    def definition(title)
      definitions.fetch(title.to_sym)
    rescue KeyError => error
      raise Errors::DefinitionNotFound.new(title)
    end

    # TODO better type parsing
    def parse_type(type)
      return type unless type.is_a?(String)

      return UUID if type.match(/uuid/i)
      return Boolean if type.match(/boolean/i)
      return Float if type.match(/number/i)
      return Time if type.match(/date.*time/i)
      Object.const_get(type.capitalize)
    rescue NameError => error
      raise Errors::InvalidType.new(type)
    end
  end

end
