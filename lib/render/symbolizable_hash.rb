module Render
  class SymbolizableHash < Hash
    def initialize
      super()
    end

    def symbolize_keys!
      keys.each do |key|
        self[(key.to_sym rescue key) || key] = delete(key)
      end
      self
    end

    def symbolize_keys
      dup.symbolize_keys!
    end

    def recursively_symbolize_keys!
      symbolize_keys!
      values.each do |value|
        value.recursively_symbolize_keys! if value.respond_to?(:recursively_symbolize_keys!)
      end
      self
    end
  end
end
