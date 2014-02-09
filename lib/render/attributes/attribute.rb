# An Attribute represents a specific key and value as part of a Schema.
# It is responsible for casting its value and generating sample data.

require "uuid"

module Render
  class Attribute
    SCHEMA_IDENTIFIERS = [:properties, :items].freeze

    attr_accessor :name,
      :type,
      :schema,
      :enums,
      :format,
      :required

    def initialize(options = {})
      Render.logger.debug("Initializing attribute #{options}")
      self.required = false
    end

    def bias_type
      format || type
    end

    def default_value
      Render.live ? nil : faux_value
    end

    def nested_schema?(options = {})
      options.any? { |name, value| SCHEMA_IDENTIFIERS.include?(name) }
    end

    private

    def process_type!(options)
      self.type = Render.parse_type(options[:type])
      self.format = Render.parse_type(options[:format]) rescue nil

      if (options[:enum])
        self.enums = options[:enum]
        self.format = Types::Enum
      end
    end

    def faux_value
      Generator.trigger(bias_type, name, self)
    end

  end
end
