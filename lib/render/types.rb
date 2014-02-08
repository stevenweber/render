require "render/types/boolean"

module Render
  module Types
    @types = {}

    class << self
      attr_accessor :types

      def add!(name, klass)
        self.types.merge!({ name.to_sym => klass })
      end

      def find(name)
        types[name.to_sym] || types[render_name(name)]
      end

      private

      def add_render_specific_type!(name)
        add!(render_name(name), Types.const_get(name))
      end

      def render_name(name)
        "render_#{name.downcase}".to_sym
      end
    end

    add_render_specific_type!(:Boolean)
  end
end
