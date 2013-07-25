# The Graph is the top-level model that defines a Schema and correlating Graphs.
# It also includes particular metadata:
#  - Endpoint to query for its schema's data
#  - Config for this endpoint, e.g. an access token
#  - Relationships between it and a Graph that includes it

require "render/schema"
require "render/errors"

module Render
  class Graph
    PARAM = %r{:(?<param>[\w_]+)}
    PARAMS = %r{#{PARAM}[\/\;\&]?}

    attr_accessor :schema,
      :raw_endpoint,
      :relationships,
      :graphs,
      :params,
      :parental_params, # TODO rename this to inherited_params
      :config

    def initialize(schema, attributes = {})
      self.schema = if schema.is_a?(Symbol)
        Schema.new(schema)
      else
        schema
      end

      self.relationships = (attributes.delete(:relationships) || {})
      self.raw_endpoint = (attributes.delete(:endpoint) || "")
      self.graphs = (attributes.delete(:graphs) || [])
      self.config = attributes
      self.parental_params = {}

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

    def pull(inherited_attributes = {})
      calculate_parental_params!(inherited_attributes)
      graph_attributes = schema.pull(inherited_attributes.merge(parental_params.merge({ endpoint: endpoint })))

      graphs.inject(graph_attributes) do |attributes, nested_graph|
        threads = []
        # TODO threading should be configured so people may also think about Thread.abort_on_transaction!
        threads << Thread.new do
          title = schema.title.to_sym
          parent_data = attributes[title]
          nested_graph_data = if parent_data.is_a?(Array)
            data = parent_data.collect do |element|
              nested_graph.pull(element)
            end
            key = data.first.keys.first
            attributes[title] = data.collect { |d| d[key] }
          else
            data = nested_graph.pull(parent_data)
            parent_data.merge!(data)
          end
        end
        threads.collect(&:join)
        DottableHash.new(attributes)
      end
    end

    private

    def initialize_params!
      self.params = raw_endpoint.scan(PARAMS).flatten.inject({}) do |params, param|
        params.merge({ param.to_sym => nil })
      end
    end

    def calculate_parental_params!(inherited)
      self.parental_params = relationships.inject(inherited) do |attributes, (parent_key, child_key)|
        attributes.merge({ child_key => inherited[parent_key] })
      end
    end

    def param_key(string)
      string.match(PARAM)[:param].to_sym
    end

    def param_value(key)
      parental_params[key] || config[key] || raise(Errors::Graph::EndpointKeyNotFound.new(key))
    end

  end
end
