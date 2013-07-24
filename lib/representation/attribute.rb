# An Attribute represents a specific key and value as part of a Schema.
# It is responsible for casting its value and generating sample (default) data when not in live-mode.
# TODO
# Arrays should really be represented by these two ways:
# { title: "beer_ids", type: Array, elements: { type: UUID } }
# { title: "beers", type: Array, elements: { type: Object, attributes: { name: { type: String } } } }
# ...or should we just standardize on attributes to be simpler? eh, I'd rather be clearer
# TODO
# Custom generators should be defined on Representation, which #faux_value can leverage with its name. e.g.
# Representation.generators = [
#   Generator.new({
#     type: String,
#     qualifiers: %w(name, first_name, last_name),
#     algorithm: lambda { Faker::Name.name }
#   })
# ]
# sudo #faux_value: Representation.generator(String, "name").call

require "uuid"

module Representation
  class Attribute
    attr_accessor :name, :type, :schema, :archetype, :enums

    # Initialize take a few different Hashes
    # { name: { type: UUID } } for standard Hashes to be aligned
    # { type: UUID } for elements in an array to be parsed
    # { name: { type: Object, attributes { ... } } for nested schemas
    def initialize(options = {})
      self.name = options.keys.first
      if (options.keys.first == :type && !options[options.keys.first].is_a?(Hash)) # todo there has to be a better way to do this
        initialize_as_archetype(options)
      else
        self.type = Representation.parse_type(options[name][:type])
        self.enums = options[name][:enum]
        initialize_schema!(options) if schema_value?(options)
      end
    end

    def initialize_as_archetype(options)
      self.type = Representation.parse_type(options[:type])
      self.enums = options[:enum]
      self.archetype = true
    end

    def initialize_schema!(options)
      schema_options = {
        title: name,
        type: type
      }

      definition = options[name]
      if definition.keys.include?(:attributes)
        schema_options.merge!({ attributes: definition[:attributes] })
      else
        schema_options.merge!({ elements: definition[:elements] })
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
      Representation.live ? nil : faux_value
    end

    def schema_value?(options = {})
      return true if schema
      options[name].is_a?(Hash) && (options[name][:attributes] || options[name][:elements])
    end

    private

    def faux_value
      # TODO implement better #faux_value
      return enums.sample if enums
      case(type.name)
      when("String") then "A String"
      when("Integer") then 1
      when("UUID") then UUID.generate
      when("Boolean") then [true, false].sample
      end
    end

  end
end

