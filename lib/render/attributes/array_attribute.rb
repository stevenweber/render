require "render/attributes/attribute"

module Render
  class ArrayAttribute < Attribute
    FAUX_DATA_UPPER_LIMIT = 5.freeze

    attr_accessor :archetype,
      :min_items,
      :max_items

    def initialize(options = {})
      super

      self.name = options.fetch(:title, :render_array_attribute_untitled).to_sym
      self.min_items = options[:minItems] || 0
      self.max_items = options[:maxItems]

      options = options.fetch(:items)
      process_type!(options)

      if options.keys.include?(:properties)
        self.schema = Schema.new(options)
      else
        self.archetype = true
      end
    end

    def serialize(explicit_values = nil)
      explicit_values = faux_array_data if (Render.live == false && explicit_values.nil?)
      if archetype
        explicit_values.collect do |value|
          value || default_value
        end
      else
        explicit_values.collect do |value|
          schema.serialize!(value)
        end
      end
    end

    private

    def faux_array_data
      faux_max = max_items || FAUX_DATA_UPPER_LIMIT
      rand(min_items..faux_max).times.collect do
        archetype ? nil : {}
      end
    end
  end
end
