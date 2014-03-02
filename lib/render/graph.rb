require "render/schema"
require "render/errors"
require "render/extensions/dottable_hash"

module Render
  class Graph
    PARAM = %r{:(?<param>[\w_]+)}
    PARAMS = %r{#{PARAM}[\/\;\&]?}

    attr_accessor :schema,
      :raw_endpoint,
      :relationships,
      :graphs,
      :inherited_data,
      :config,
      :rendered_data,
      :relationship_info

    def initialize(schema_or_definition, options = {})
      self.schema = determine_schema(schema_or_definition)
      self.relationships = (options.delete(:relationships) || {})
      self.graphs = (options.delete(:graphs) || [])
      self.raw_endpoint = (options.delete(:endpoint) || schema.definition[:endpoint]).to_s
      self.config = options
      self.relationship_info = {}

      self.inherited_data = {}
    end

    def title
      schema.universal_title || schema.title
    end

    def process_relationship_info!(data)
      return if !data

      self.relationship_info = relationships.inject({}) do |info, (parent_key, child_key)|
        value = data.is_a?(Hash) ? data.fetch(parent_key, nil) : data
        info.merge!({ child_key => value })
      end
    end

    def serialize!(explicit_data = nil, parental_data = nil)
      process_relationship_info!(parental_data)

      if (schema.type == Array)
        schema.render!(explicit_data, endpoint)
      else
        explicit_data ||= {}
        schema.render!(explicit_data.merge(relationship_info), endpoint)
      end
    end

    def render!(explicit_data = nil, parental_data = nil, as_array = false)
      if as_array
        data = parental_data.inject([]) do |accumulator, parental_element|
          accumulator << serialize!(explicit_data, parental_element)
        end
      else
        data = serialize!(explicit_data, parental_data)
      end

      loop_with_configured_threading(graphs) do |graph|
        graph.render!(explicit_data, data, (schema.type == Array))
      end

      self.rendered_data = graphs.inject(Extensions::DottableHash.new) do |data, graph|
        data[graph.title] = graph.rendered_data
      end
      self.rendered_data[title] = data
      rendered_data
    end

    private

    def endpoint
      raw_endpoint.gsub!(":host", config.fetch(:host)) if raw_endpoint.match(":host")
      uri = URI(raw_endpoint)

      uri.path.gsub!(PARAMS) do |param|
        key = param_key(param)
        param.gsub(PARAM, param_value(key).to_s)
      end

      if uri.query
        uri.query.gsub!(PARAMS) do |param|
          key = param_key(param)
          "#{key}=#{param_value(key)}&"
        end.chop!
      end

      uri.to_s
    end

    def param_key(string)
      string.match(PARAM)[:param].to_sym
    end

    def param_value(key)
      relationship_info[key] || config[key] || raise(Errors::Graph::EndpointKeyNotFound.new(key))
    end

    def loop_with_configured_threading(elements)
      if Render.threading?
        threads = []
        elements.each do |element|
          threads << Thread.new do
            yield element
          end
        end
        threads.collect(&:join)
      else
        elements.each do |element|
          yield element
        end
      end
    end

    def determine_schema(schema_or_definition)
      if schema_or_definition.is_a?(Schema)
        schema_or_definition
      else
        Schema.new(schema_or_definition)
      end
    end

  end
end
