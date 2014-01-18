require "render"
require "render/attribute"

module Render
  class HashAttribute < Attribute
    def initialize(options = {})
      super

      self.name = options.keys.first
      options = options[name]
      self.type = Render.parse_type(options[:type])
      self.format = Render.parse_type(options[:format]) rescue nil
      self.enums = options[:enum]

      initialize_schema!(options) if nested_schema?(options)
    end

    def initialize_schema!(options)
      schema_options = {
        title: name,
        type: bias_type
      }

      self.schema = Schema.new(schema_options.merge(options))
    end

    def serialize(explicit_value, maintain_nil = false)
      if !!schema
        value = schema.serialize!(explicit_value)
        { name.to_sym => value }
      else
        if (maintain_nil && !explicit_value)
          value = nil
        else
          value = (explicit_value || default_value)
        end

        { name.to_sym => value }
      end
    end

  end
end
