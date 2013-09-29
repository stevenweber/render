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
      :params,
      :inherited_params,
      :config

    def initialize(schema, options = {})
      self.schema = if schema.is_a?(Symbol)
        Schema.new(schema)
      else
        schema
      end

      self.relationships = (options.delete(:relationships) || {})
      self.raw_endpoint = (options.delete(:endpoint) || "")
      self.graphs = (options.delete(:graphs) || [])
      self.config = options
      self.inherited_params = {}

      initialize_params!
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

    def prepare!(inherited_attributes = {})
      calculate_inherited_params!(inherited_attributes)
    end

    def render(inherited_properties = {})
      prepare!(inherited_properties)
      graph_properties = schema.render(inherited_properties.merge(inherited_params.merge({ endpoint: endpoint })))

      graph = graphs.inject(graph_properties) do |properties, nested_graph|
        threads = []
        # TODO threading should be configured so people may also think about Thread.abort_on_transaction!
        # threads << Thread.new do
          title = schema.title.to_sym
          parent_data = properties[title]
          nested_graph_data = if parent_data.is_a?(Array)
            data = parent_data.collect do |element|
              nested_graph.render(element)
            end
            key = data.first.keys.first
            properties[title] = data.collect { |d| d[key] }
          else
            data = nested_graph.render(parent_data)
            parent_data.merge!(data)
          end
        # end
        # threads.collect(&:join)
        properties
      end
      DottableHash.new(graph)
    end

    private

    def initialize_params!
      self.params = raw_endpoint.scan(PARAMS).flatten.inject({}) do |params, param|
        params.merge({ param.to_sym => nil })
      end
    end

    def calculate_inherited_params!(inherited)
      self.inherited_params = relationships.inject(inherited) do |properties, (parent_key, child_key)|
        properties.merge({ child_key => inherited[parent_key] })
      end
    end

    def param_key(string)
      string.match(PARAM)[:param].to_sym
    end

    def param_value(key)
      inherited_params[key] || config[key] || raise(Errors::Graph::EndpointKeyNotFound.new(key))
    end

  end
end
