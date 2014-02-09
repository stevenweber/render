# Render allows one to define object Graphs with Schema/endpoint information.
# Once defined and constructed, a Graph can be built at once that will:
#  - Query its endpoint to construct a hash for its Schema
#  - Add nested Graphs by interpreting/sending data they need

require "uuid"
require "date"
require "logger"

require "render/version"
require "render/extensions/dottable_hash"
require "render/errors"
require "render/types"
require "render/graph"
require "render/generator"

module Render
  @live = true
  @definitions = {}
  @logger = ::Logger.new("/dev/null")
  @threading = true

  class << self
    attr_accessor :live,
      :definitions,
      :logger,
      :threading

    def threading?
      threading == true
    end

    def load_definitions!(directory)
      Dir.glob("#{directory}/**/*.json").each do |definition_file|
        logger.info("Reading #{definition_file} definition")
        definition_string = File.read(definition_file)
        json_definition = JSON.parse(definition_string)
        parsed_definition = Extensions::DottableHash.new(json_definition).recursively_symbolize_keys!
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

    def parse_type(type)
      Render::Types.parse(type)
    end
  end
end
