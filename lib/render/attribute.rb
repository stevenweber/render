# An Attribute represents a specific key and value as part of a Schema.
# It is responsible for casting its value and generating sample (default) data when not in live-mode.

require "uuid"

module Render
  class Attribute
    attr_accessor :name, :type, :schema, :archetype, :enums, :format

    # Initialize take a few different Hashes
    # { name: { type: UUID } } for standard Hashes to be aligned
    # { type: UUID } for items in an array to be parsed
    # { format: "uuid" }
    # { name: { type: Object, properties { ... } } for nested schemas
    def initialize(options = {})
      Render.logger.debug("Initializing attribute #{options}")
      self.name = options.keys.first
      if (options.keys.first == :type && !options[options.keys.first].is_a?(Hash)) # todo there has to be a better way to do this
        initialize_as_archetype(options)
      else
        self.type = Render.parse_type(options[name][:type])
        self.enums = options[name][:enum]
        self.format = options[name][:format]
        initialize_schema!(options) if schema_value?(options)
      end
    end

    def initialize_as_archetype(options)
      bias_type = options[:format] || options[:type]
      self.type = Render.parse_type(bias_type)
      self.format = options[:format]
      self.enums = options[:enum]
      self.archetype = true
    end

    def initialize_schema!(options)
      schema_options = {
        title: name,
        type: type
      }

      definition = options[name]
      if definition.keys.include?(:properties)
        schema_options.merge!({ properties: definition[:properties] })
      else
        schema_options.merge!({ items: definition[:items] })
      end

      self.schema = Schema.new(schema_options)
    end

    def serialize(explicit_value)
      if archetype
        explicit_value || default_value
      else
        to_hash(explicit_value)
      end
    end

    def to_hash(explicit_value = nil)
      value = if schema_value?
        schema.serialize(explicit_value)
      else
        # TODO guarantee type for explicit value
        (explicit_value || default_value)
      end

      { name.to_sym => value }
    end

    def default_value
      Render.live ? nil : faux_value
    end

    def schema_value?(options = {})
      return true if schema
      options[name].is_a?(Hash) && (options[name][:properties] || options[name][:items])
    end

    private

    def faux_value
      # TODO implement better #faux_value
      return enums.sample if enums
      return generator_value if generator_value # todo optimize generator_value call

      bias_type = Render.parse_type(format) rescue nil
      bias_type ||= type

      case(bias_type.name)
      when("String") then "A String"
      when("Integer") then rand(1000)
      when("UUID") then UUID.generate
      when("Boolean") then [true, false].sample
      when("Float") then rand(0.1..99)
      end
    end

    def generator_value
      generator = Render.generators.detect do |generator|
        generator.type == type && name.match(generator.matcher)
      end
      generator.algorithm.call if generator
    end

  end
end

