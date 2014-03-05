require "net/http"
require "json"
require "render"
require "render/attributes/array_attribute"
require "render/attributes/hash_attribute"
require "render/extensions/dottable_hash"

module Render
  class Schema
    DEFAULT_TITLE = "untitled".freeze
    CONTAINER_KEYWORDS = %w(items properties).freeze

    attr_accessor :title,
      :type,
      :definition,
      :array_attribute,
      :hash_attributes

    def initialize(definition_or_title)
      Render.logger.debug("Loading #{definition_or_title}")

      process_definition!(definition_or_title)
      interpolate_refs!(definition)

      self.title = definition.fetch(:title, DEFAULT_TITLE)
      self.type = Type.parse(definition[:type]) || Object

      if array_schema?
        self.array_attribute = ArrayAttribute.new(definition)
      else
        self.hash_attributes = definition.fetch(:properties).collect do |name, attribute_definition|
          HashAttribute.new({ name => attribute_definition })
        end
        require_attributes!
      end
    end

    def id
      Definition.id(definition)
    end

    def serialize!(explicit_data = nil)
      if (type == Array)
        array_attribute.serialize(explicit_data)
      else
        hash_attributes.inject({}) do |processed_explicit_data, attribute|
          explicit_data ||= {}
          value = explicit_data.fetch(attribute.name, nil)
          maintain_nil = explicit_data.has_key?(attribute.name)
          serialized_attribute = attribute.serialize(value, maintain_nil)
          processed_explicit_data.merge!(serialized_attribute)
        end
      end
    end

    def render!(explicit_data = nil, endpoint = nil)
      raw_data = Render.live ? request(endpoint) : explicit_data
      data = serialize!(raw_data)
      data.is_a?(Array) ? data : Extensions::DottableHash.new(data)
    end

    def attributes
      array_schema? ? array_attribute : hash_attributes
    end

    private

    def require_attributes!
      definition.fetch(:required, []).each do |required_attribute|
        attribute = attributes.detect { |attribute| attribute.name == required_attribute.to_sym }
        attribute.required = true
      end
    rescue
      raise Errors::Schema::InvalidRequire.new(definition)
    end

    def process_definition!(title_or_definition)
      raw_definition = determine_definition(title_or_definition)

      if container?(raw_definition)
        self.definition = raw_definition
      else
        partitions = raw_definition.partition { |(key, value)| container?(value) }
        subschemas, container = partitions.map { |partition| Hash[partition] }
        container[:type] = Object
        container[:properties] = subschemas

        self.definition = container
      end
    end

    def interpolate_refs!(definition)
      return unless definition.is_a?(Hash)

      definition.each do |(instance_name, instance_value)|
        next unless instance_value.is_a?(Hash)

        ref_definition = find_ref(instance_value)
        if ref_definition
          interpolate_refs!(ref_definition)
          instance_value.replace(ref_definition)
        end

        interpolate_refs!(instance_value)
      end
    end

    def container?(definition)
      return false unless definition.is_a?(Hash)
      definition.any? { |(key, value)| CONTAINER_KEYWORDS.include?(key.to_s) }
    end

    def find_ref(definition)
      ref = definition[:$ref]
      return unless ref
      relative_definition = find_relative_definition(ref)
      relative_definition.empty? ? Definition.find(ref) : relative_definition
    end

    def find_relative_definition(ref)
      paths = ref.split(/[#\/]/).delete_if { |path| path.empty? }
      paths.reduce(definition) do |reduction, path|
        reduction.fetch(path.to_sym, {})
      end
    end

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

    def request(endpoint)
      default_request(endpoint)
    end

    def default_request(endpoint)
      response = Net::HTTP.get_response(URI(endpoint))
      if response.kind_of?(Net::HTTPSuccess)
        JSON.parse(response.body.to_s, { symbolize_names: true })
      else
        raise Errors::Schema::RequestError.new(endpoint, response)
      end
    rescue JSON::ParserError => error
      raise Errors::Schema::InvalidResponse.new(endpoint, response.body)
    end

  end
end
