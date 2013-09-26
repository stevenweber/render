# The Schema defines a collection of properties.
# It is responsible for returning its properties' values back to its Graph.

require "net/http"
require "json"
require "render"
require "render/attribute"

module Render
  class Schema
    attr_accessor :title,
      :type,
      :properties,
      :schema

    # The schema need to know where its getting a value from
    # an Attribute, e.g. { foo: "bar" } => { foo: { type: String } }
    # an Archetype, e.g. [1,2,3] => { type: Integer } # could this be a pass-through?
    # an Attribute-Schema, e.g. { foo: { bar: "baz" } } => { foo: { type: Object, properties: { bar: { type: String } } }
    # an Attribute-Array, e.g. [{ foo: "bar" }] => { type: Array, items: { type: Object, properties: { foo: { type: String } } } }
    # and we need to identify when given { ids: [1,2] }, parental_mapping { ids: id } means to make 2 calls
    def initialize(schema_or_title)
      self.schema = schema_or_title.is_a?(Hash) ? schema_or_title : find_schema(schema_or_title)
      Render.logger.debug("Loading #{schema_or_title}")
      self.title = schema[:title]
      self.type = Render.parse_type(schema[:type])

      if array_of_schemas?(schema[:items])
        self.properties = [Attribute.new({ items: schema[:items] })]
      elsif array_of_archetypes?(schema[:items])
        options = { type: schema[:items][:type], format: schema[:items][:format], enum: schema[:items][:enum] }
        self.properties = [Attribute.new(options)]
      else
        definitions = schema[:properties] || schema[:items]
        self.properties = definitions.collect do |key, value|
          Attribute.new({ key => value })
        end
      end
    end

    def array_of_schemas?(definition = {})
      return false unless definition
      definition.keys.include?(:properties)
    end

    def array_of_archetypes?(definition = {})
      # TODO test this
      return false unless definition
      !definition.keys.include?(:properties)
    end

    def render(options = {})
      endpoint = options.delete(:endpoint)
      data = Render.live ? request(endpoint) : options
      { title.to_sym => serialize(data) }
    end

    def serialize(data)
      # data.is_a?(Array) ? to_array(data) : to_hash(data)
      (type == Array) ? to_array(data) : to_hash(data)
    end

    private

    def find_schema(title)
      loaded_schema = Render.schemas[title.to_sym]
      raise Errors::Schema::NotFound.new(title) if !loaded_schema
      loaded_schema
    end

    def request(endpoint)
      response = Net::HTTP.get_response(URI(endpoint)) # TODO Custom requests
      if response.kind_of?(Net::HTTPSuccess)
        response = JSON.parse(response.body).recursive_symbolize_keys!
        if (response.is_a?(Array) || (response[title.to_sym] == nil))
          response
        else
          response[title.to_sym]
        end
      else
        raise Errors::Schema::RequestError.new(endpoint, response)
      end
    rescue JSON::ParserError => error
      raise Errors::Schema::InvalidResponse.new(endpoint, response.body)
    end

    def to_array(items)
      # items.first.is_a?(Hash) ? to_array_of_schemas(items) : to_array_of_items(items)
      properties.first.schema_value? ? to_array_of_schemas(items) : to_array_of_items(items)
    end

    def to_array_of_items(items)
      (items = stubbed_array) if !Render.live && (!items || items.empty?)
      archetype = properties.first # there should only be one in the event that it's an array schema
      items.collect do |element|
        archetype.serialize(element)
      end
    end

    def to_array_of_schemas(items)
      (items = stubbed_array) if !Render.live && (!items || items.empty?)
      items.collect do |element|
        properties.inject({}) do |properties, attribute|
          properties.merge(attribute.to_hash(element)).values.first
        end
      end
    end

    def to_hash(explicit_values = {})
      explicit_values ||= {} # !Render.live check
      properties.inject({}) do |accum, attribute|
        explicit_value = explicit_values[attribute.name]
        hash = attribute.to_hash(explicit_value)
        accum.merge(hash)
      end
    end

    def stubbed_array
      items = []
      rand(1..3).times { items << nil }
      items
    end
  end
end
