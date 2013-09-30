require "render/attribute"

module Render
  class ArrayAttribute < Attribute
    attr_accessor :archetype

    def initialize(options = {})
      super

      options = options[:items]
      self.type = Render.parse_type(options[:type])
      self.format = Render.parse_type(options[:format])
      self.enums = options[:enum]

      if options.keys.include?(:properties)
        self.schema = Schema.new(options)
      else
        self.archetype = true
      end
    end

    def serialize(explicit_values)
      explicit_values = faux_array_data if (Render.live == false)
      if archetype
        explicit_values.collect do |value|
          Render.live ? value : faux_value
        end
      else
        explicit_values.collect do |value|
          schema.serialize(value)
        end
      end
    end

    private

    def faux_array_data
      lower_limit = (required ? 1 : 0)
      upper_limit = 5
      rand(lower_limit..upper_limit).times.collect do
        archetype ? nil : {}
      end
    end

  end
end
