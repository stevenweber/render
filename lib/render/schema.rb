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
    attr_accessor :title,
      :type,
      :definition,
      :array_attribute,
      :hash_attributes,
      :data

    # TODO When given { ids: [1,2] }, parental_mapping { ids: id } means to make 2 calls
    def initialize(definition_or_title)
      Render.logger.debug("Loading #{definition_or_title}")
      self.definition = Render.definitions.fetch(definition_or_title, definition_or_title)
      title_or_default = definition.fetch(:title, "untitled")
      self.title = title_or_default.to_sym
      self.type = Render.parse_type(definition[:type])

      if definition.keys.include?(:items)
        self.array_attribute = ArrayAttribute.new(definition)
      else
        self.hash_attributes = definition.fetch(:properties).collect do |name, attribute_definition|
          HashAttribute.new({ name => attribute_definition })
        end
      end
    end

    def serialize(data = nil)
      if (type == Array)
        array_attribute.serialize(data)
      else
        hash_attributes.inject({}) do |processed_data, attribute|
          data ||= {}
          value = data.fetch(attribute.name, nil)
          serialized_attribute = attribute.serialize(value)
          processed_data.merge!(serialized_attribute)
        end
      end
    end

    def render(options = nil)
      response = Render.live ? request(options.delete(:endpoint)) : options
      data = (response.is_a?(Hash) ? (response[title.to_sym] || response) : response)
      self.data = DottableHash.new({ title.to_sym => serialize(data) })
    end

    private

    # TODO Make this configurable via a proc
    def request(endpoint)
      response = Net::HTTP.get_response(URI(endpoint)) # TODO Custom requests
      if response.kind_of?(Net::HTTPSuccess)
        JSON.parse(response.body).recursive_symbolize_keys!
      else
        raise Errors::Schema::RequestError.new(endpoint, response)
      end
    rescue JSON::ParserError => error
      raise Errors::Schema::InvalidResponse.new(endpoint, response.body)
    end

    def stubbed_array
      items = []
      rand(1..3).times { items << nil }
      items
    end
  end
end
