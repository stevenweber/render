require "render/extensions/symbolizable_hash"
require "render/extensions/symbolizable_array"

module Render
  module Extensions
    class DottableHash < SymbolizableHash
      class << self
        def new(element_to_hash = {})
          symbolize_hash = SymbolizableHash.new.merge!(element_to_hash)
          symbolize_hash.symbolize_keys!
          hash = super().merge!(symbolize_hash)

          hash.each do |key, value|
            hash[key] = initialize_element(value)
          end

          hash
        end

        def initialize_element(value)
          case value
          when Hash
            new(value)
          when Array
            values = value.collect do |v|
              initialize_element(v)
            end
            SymbolizableArray.new(values)
          else
            value
          end
        end
      end

      def []=(key, value)
        key = key.to_sym
        value = self.class.initialize_element(value)
        super
      end

      def [](key)
        key = key.to_sym
        super
      end

      def delete(key)
        key = key.to_sym
        super
      end

      def has_key?(key)
        super(key.to_sym)
      end

      def merge!(other_hash)
        other_hash = SymbolizableHash.new().merge!(other_hash)
        super(other_hash.recursively_symbolize_keys!)
      end

      def merge(other_hash)
        other_hash = SymbolizableHash.new().merge!(other_hash)
        super(other_hash.recursively_symbolize_keys!)
      end

      def method_missing(method, *arguments)
        if method.match(/\=$/)
          self[method.to_s.chop] = arguments.first
        elsif has_key?(method)
          self[method]
        else
          super
        end
      end

      def fetch(key, *args)
        key = key.to_sym
        super
      end

    end
  end
end
