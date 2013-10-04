module Render
  class DottableHash < Hash
    class << self
      def new(element_to_hash = {})
        hash = super().merge!(element_to_hash.symbolize_keys)
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
          value.collect { |v| initialize_element(v) }
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
      super(other_hash.symbolize_keys)
    end

    def merge(other_hash)
      super(other_hash.symbolize_keys)
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

    def fetch_path(full_path)
      begin
        fetch_path!(full_path)
      rescue KeyError
        nil
      end
    end

    def fetch_path!(full_path)
      full_path.split(".").inject(self) do |hash, path|
        raise(KeyError) unless hash.is_a?(Hash)

        hash.fetch(path)
      end
    end

    def set_path(full_path, value)
      self.dup.set_path!(full_path, value)
    end

    def set_path!(full_path, value)
      built_hash_for_value = full_path.split(".").reverse.inject({}) do |cumulative, path_to_source|
        if cumulative.empty?
          { path_to_source.to_sym => value }
        else
          { path_to_source.to_sym => cumulative }
        end
      end

      deep_merge!(built_hash_for_value)
    end

    protected

    def deep_merge(other_hash)
      merge(other_hash) do |key, oldval, newval|
        oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
        newval = newval.to_hash if newval.respond_to?(:to_hash)
        oldval.is_a?(Hash) && newval.is_a?(Hash) ? self.class.new(oldval).deep_merge(newval) : self.class.new(newval)
      end
    end

    def deep_merge!(other_hash)
      replace(deep_merge(other_hash))
    end
  end
end
