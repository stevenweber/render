# The Schema defines a collection of properties.
# It is responsible for returning its properties' values back to its Graph.

require "net/http"
require "json"
require "render"
require "render/attribute"
require "render/array_attribute"
require "render/hash_attribute"
require "render/dottable_hash"

module Render
  class Schema
    DEFAULT_TITLE = "untitled".freeze

    attr_accessor :title,
      :type,
      :definition,
      :array_attribute,
      :hash_attributes,
      :raw_data,
      :universal_title

    # TODO When given { ids: [1,2] }, parental_mapping { ids: id } means to make 2 calls
    def initialize(definition_or_title)
      Render.logger.debug("Loading #{definition_or_title}")

      set_definition!(definition_or_title)
      title_or_default = definition.fetch(:title, DEFAULT_TITLE)
      self.title = title_or_default.to_sym
      self.type = Render.parse_type(definition[:type])
      self.universal_title = definition.fetch(:universal_title, nil)

      if definition.keys.include?(:items)
        self.array_attribute = ArrayAttribute.new(definition)
      else
        self.hash_attributes = definition.fetch(:properties).collect do |name, attribute_definition|
          HashAttribute.new({ name => attribute_definition })
        end
      end
    end

    def set_definition!(definition_or_title)
      self.definition = if (definition_or_title.is_a?(Hash) && !definition_or_title.empty?)
        definition_or_title
      else
        Render.definition(definition_or_title)
      end
    end

    def serialize(explicit_data = nil)
      if (type == Array)
        array_attribute.serialize(explicit_data)
      else
        hash_attributes.inject({}) do |processed_explicit_data, attribute|
          explicit_data ||= {}
          value = explicit_data.fetch(attribute.name, nil)
          serialized_attribute = attribute.serialize(value)
          processed_explicit_data.merge!(serialized_attribute)
        end
      end
    end

    def render(options_and_explicit_data = nil)
      endpoint = options_and_explicit_data.delete(:endpoint) if options_and_explicit_data.is_a?(Hash)
      self.raw_data = Render.live ? request(endpoint) : options_and_explicit_data
      processed_data = serialize(biased_data)
      DottableHash.new(hash_with_title_prefixes(processed_data))
    end

    private

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
        JSON.parse(response.body).recursive_symbolize_keys!
      else
        raise Errors::Schema::RequestError.new(endpoint, response)
      end
    rescue JSON::ParserError => error
      raise Errors::Schema::InvalidResponse.new(endpoint, response.body)
    end

    def biased_data
      data_uses_title_as_root_key? ? raw_data.fetch(title) : raw_data
    end

    def data_uses_title_as_root_key?
      raw_data.is_a?(Hash) && raw_data.has_key?(title)
    end

  end
end
