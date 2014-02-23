require "uuid"

module Render
  class Attribute
    SCHEMA_IDENTIFIERS = [:properties, :items].freeze

    attr_accessor :name,
      :type,
      :schema,
      :enums,
      :format,
      :min_length,
      :max_length

    attr_writer :default

    def initialize(options = {})
      Render.logger.debug("Initializing attribute #{options}")
    end

    def bias_type
      format || type
    end

    def default_value
      @default || (Render.live ? nil : faux_value)
    end

    def nested_schema?(options = {})
      options.any? { |name, value| SCHEMA_IDENTIFIERS.include?(name) }
    end

    private

    def process_options!(options)
      self.type = Type.parse!(options[:type])
      self.format = Type.parse(options[:format])

      if (options[:enum])
        self.enums = options[:enum]
        self.format = Type::Enum
      end

      @default = options[:default]
      self.min_length = options[:minLength]
      self.max_length = options[:maxLength]
    end

    def faux_value
      Generator.trigger(bias_type, name, self)
    end

  end
end
