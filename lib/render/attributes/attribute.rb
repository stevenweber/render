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

    def generator
      @generator ||= Render.generators.detect do |generator|
        generator.type == type && name.match(generator.matcher)
      end
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

    def faux_value
      return enums.sample if enums
      return generator.algorithm.call if generator

      case(bias_type.name)
      when("String") then "#{name} (generated)"
      when("Integer") then rand(1000)
      when("UUID") then UUID.generate
      when("Boolean") then [true, false].sample
      when("Float") then rand(0.1..99).round(2)
      when("Time")
        time = Time.now
        (type == String) ? time.to_s : time
      end
    end

  end
end
