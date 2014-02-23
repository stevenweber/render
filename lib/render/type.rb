# Render::Type defines classes for JSON Types and Formats.
# Add additional types for your specific needs, along with a generator to create fake data for it.

require "uuid"
require "date"
require "ipaddr"
require "uri"

module Render
  module Type
    @instances = {}

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
        return nil if (name == "null")

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

    class Enum; end
    class Boolean; end
    class Date; end
    class Hostname < String; end
    class Email < String; end
    class IPv4 < IPAddr; end
    class IPv6 < IPAddr; end

    # Standard types
    add!(:number, Float)
    add!(:null, nil)
    add_render_specific_type!(:Enum)
    add_render_specific_type!(:Boolean)

    # Standard formats
    add!(:uri, URI)
    add!("date-time".to_sym, DateTime)
    add_render_specific_type!(:IPv4)
    add_render_specific_type!(:IPv6)
    add_render_specific_type!(:Email)
    add_render_specific_type!(:Hostname)

    # Extended
    add!(:uuid, UUID)
    add_render_specific_type!(:Date)

  end
end
