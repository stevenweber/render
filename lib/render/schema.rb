require "net/http"
require "json"
require "render"
require "render/attributes/array_attribute"
require "render/attributes/hash_attribute"
require "render/extensions/dottable_hash"

module Render
  class Schema
    DEFAULT_TITLE = "untitled".freeze

    attr_accessor :title,
      :type,
      :definition,
      :array_attribute,
      :hash_attributes,
      :universal_title,
      :raw_data,
      :serialized_data,
      :rendered_data

    def initialize(definition_or_title)
      Render.logger.debug("Loading #{definition_or_title}")
      self.definition = determine_definition(definition_or_title)
      title_or_default = definition.fetch(:title, DEFAULT_TITLE)
      self.title = title_or_default.to_sym
      self.type = Type.parse(definition[:type]) || Object
      self.universal_title = definition.fetch(:universal_title, nil)

      if array_schema?
        self.array_attribute = ArrayAttribute.new(definition)
      else
        self.hash_attributes = definition.fetch(:properties).collect do |name, attribute_definition|
          HashAttribute.new({ name => attribute_definition })
        end

        definition.fetch(:required, []).each do |required_attribute|
          attribute = attributes.detect { |attribute| attribute.name == required_attribute.to_sym }
          raise Errors::Schema::InvalidRequire.new(required_attribute) unless attribute
          attribute.required = true
        end
      end
    end

    def serialize!(explicit_data = nil)
      if (type == Array)
        self.serialized_data = array_attribute.serialize(explicit_data)
      else
        self.serialized_data = hash_attributes.inject({}) do |processed_explicit_data, attribute|
          explicit_data ||= {}
          value = explicit_data.fetch(attribute.name, nil)
          maintain_nil = explicit_data.has_key?(attribute.name)

          serialized_attribute = attribute.serialize(value, maintain_nil)
          processed_explicit_data.merge!(serialized_attribute)
        end
      end
    end

    def render!(explicit_data = nil, endpoint = nil)
      self.raw_data = Render.live ? request(endpoint) : explicit_data
      serialize!(raw_data)
      yield serialized_data if block_given?
      self.rendered_data = Extensions::DottableHash.new(hash_with_title_prefixes(serialized_data))
    end

    def attributes
      array_schema? ? array_attributes : hash_attributes
    end

    private

    def array_schema?
      definition.keys.include?(:items)
    end

    def determine_definition(definition_or_title)
      if (definition_or_title.is_a?(Hash) && !definition_or_title.empty?)
        definition_or_title
      else
        Definition.find(definition_or_title)
      end
    end

    def hash_with_title_prefixes(data)
      if universal_title
        { universal_title => { title => data } }
      else
        { title => data }
      end
    end

    def request(endpoint)
      default_request(endpoint)
    end

    def default_request(endpoint)
      response = Net::HTTP.get_response(URI(endpoint))
      if response.kind_of?(Net::HTTPSuccess)
        response = JSON.parse(response.body.to_s)
        if response.is_a?(Array)
          Extensions::SymbolizableArray.new(response).recursively_symbolize_keys!
        else
          Extensions::DottableHash.new(response).recursively_symbolize_keys!
        end
      else
        raise Errors::Schema::RequestError.new(endpoint, response)
      end
    rescue JSON::ParserError => error
      raise Errors::Schema::InvalidResponse.new(endpoint, response.body)
    end

  end
end
