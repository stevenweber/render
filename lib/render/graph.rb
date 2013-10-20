# The Graph is the top-level model that defines a Schema and correlating Graphs.
# It also includes particular metadata:
#  - Endpoint to query for its schema's data
#  - Config for this endpoint, e.g. an access token
#  - Relationships between it and a Graph that includes it

require "render/schema"
require "render/errors"
require "render/dottable_hash"

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
      :rendered_data

    def initialize(schema_or_definition, options = {})
      self.schema = determine_schema(schema_or_definition)
      self.relationships = (options.delete(:relationships) || {})
      self.graphs = (options.delete(:graphs) || [])
      self.raw_endpoint = options.delete(:endpoint).to_s
      self.config = options

      self.inherited_data = {}
    end

    def endpoint
      uri = URI(raw_endpoint)

      uri.path.gsub!(PARAMS) do |param|
        key = param_key(param)
        param.gsub(PARAM, param_value(key))
      end

      if uri.query
        uri.query.gsub!(PARAMS) do |param|
          key = param_key(param)
          "#{key}=#{param_value(key)}&"
        end.chop!
      end

      uri.to_s
    end

    def render(inherited_properties = {})
      self.inherited_data = inherited_properties

      graph_data = DottableHash.new
      schema.render!(relationship_data_from_parent.merge({ endpoint: endpoint })) do |parent_data|
        # TODO Thread support with configurable raises
        # threads = []
        graphs.each do |graph|
          # threads << Thread.new do
            if parent_data.is_a?(Array)
              graph_data[graph.title] = parent_data.inject([]) do |nested_data, element|
                nested_data << graph.render(element)[graph.title]
              end
            else
              nested_data = graph.render(parent_data)
              graph_data.merge!(data)
            end
          # end
        end
        # threads.collect(&:join)
      end

      self.rendered_data = graph_data.merge!(schema.rendered_data)
    end

    def title
      schema.universal_title || schema.title
    end

    private

    def determine_schema(schema_or_definition)
      if schema_or_definition.is_a?(Schema)
        schema_or_definition
      else
        Schema.new(schema_or_definition)
      end
    end

    def relationship_data_from_parent
      relationships.inject({}) do |data, (parent_key, child_key)|
        data.merge({ child_key => value_from_inherited_data(child_key) })
      end
    end

    def param_key(string)
      string.match(PARAM)[:param].to_sym
    end

    def param_value(key)
      value_from_inherited_data(key) || config[key] || raise(Errors::Graph::EndpointKeyNotFound.new(key))
    end

    def value_from_inherited_data(key)
      relationships.each do |parent_key, child_key|
        if (child_key == key)
          return inherited_data.fetch(parent_key)
        end
      end
      nil
    end

  end
end
