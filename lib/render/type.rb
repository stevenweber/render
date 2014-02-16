# Types define classes of data being interpreted. This is especially important in modeling fake data.
# Add additional types for your specific needs, along with a generator to create fake data for it.

require "uuid"

module Render
  module Type
    @instances = {}

    class Enum; end
    class Boolean; end
    class Date; end

    class << self
      attr_accessor :instances

      def add!(name, klass)
        self.instances.merge!({ formatted_name(name) => klass })
      end

      def find(name)
        class_for_name(name) || class_for_name(render_name(name))
      end

      def parse(name, raise_error = false)
        return name unless name.is_a?(String)
        Render::Type.find(name) || Object.const_get(name.capitalize)
      rescue NameError
        raise Errors::InvalidType.new(name) if raise_error
      end

      def parse!(name)
        parse(name, true)
      end

      private

      def class_for_name(name)
        instances.each do |(instance_name, instance_class)|
          return instance_class if name.to_s.match(/#{instance_name}/i)
        end
        nil
      end

      def formatted_name(name)
        name.to_s.downcase.to_sym
      end

      def render_name(name)
        formatted_name("render_#{name}")
      end

      def add_render_specific_type!(name)
        add!(render_name(name), Type.const_get(name))
      end
    end

    add!(:uuid, UUID)
    add!(:number, Float)
    add!(:time, Time)
    add_render_specific_type!(:Boolean)
    add_render_specific_type!(:Enum)
    add_render_specific_type!(:Date)
  end
end
