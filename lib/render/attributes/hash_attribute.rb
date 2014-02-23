require "render"
require "render/attributes/attribute"

module Render
  class HashAttribute < Attribute
    attr_accessor :required

    def initialize(options = {})
      super

      self.name = options.keys.first
      options = options[name]

      process_options!(options)
      self.required = !!options[:required]

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
          value = explicit_value
        else
          value = (explicit_value || default_value)
        end

        { name.to_sym => Type.to(type, value) }
      end
    end

  end
end
