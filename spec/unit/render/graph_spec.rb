# encoding: utf-8
require "render/graph"
require "uuid"

module Render
  describe Graph do
    before(:each) do
      Render.stub({ live: false })
      @schema = double(:schema)
    end

    describe ".initialize" do
      describe "schema" do
        it "is set with argument" do
          graph = Graph.new(@schema)
          graph.schema.should == @schema
        end

        it "is set with preloaded schema" do
          Schema.should_receive(:new).with(:film).and_return(:new_schema)
          Graph.new(:film).schema.should == :new_schema
        end
      end

      it "sets attributes from options" do
        relationships = { director_id: :id }
        graphs = [double(:graph)]
        graph = Graph.new(@schema, {
          relationships: relationships,
          graphs: graphs,
        })

        graph.relationships.should == relationships
        graph.graphs.should == graphs
      end

      it "sets config from options that are not attributes" do
        relationships = { some: :relationship }
        client_id = UUID.generate
        graph = Graph.new(@schema, {
          relationships: relationships,
          client_id: client_id
        })

        graph.config.should == { client_id: client_id }
      end

      it "parses endpoint params from options" do
        endpoint = "http://endpoint.local/:id?client_id=:client_id"
        graph = Graph.new(@schema, { endpoint: endpoint })
        graph.params.should == { id: nil, client_id: nil }
      end
    end

    describe ".endpoint" do
      it "returns #raw_endpoint" do
        simple_endpoint = "http://endpoint.local"
        graph = Graph.new(@schema, { endpoint: simple_endpoint })
        graph.endpoint.should == simple_endpoint
      end

      it "interpolates inherited parameters" do
        director_id = UUID.generate
        endpoint = "http://endpoint.local/directors/:id"
        relationships = { director_id: :id }

        graph = Graph.new(@schema, { endpoint: endpoint, relationships: relationships })
        graph.prepare!({ director_id: director_id })

        graph.endpoint.should == "http://endpoint.local/directors/#{director_id}"
      end

      it "interpolates config options" do
        client_id = UUID.generate
        endpoint = "http://endpoint.local/?:client_id"

        graph = Graph.new(@schema, { endpoint: endpoint, client_id: client_id })
        graph.endpoint.should == "http://endpoint.local/?client_id=#{client_id}"
      end

      it "raises an error if no value can be found" do
        endpoint = "http://endpoint.com/?:undefined_key"
        graph = Graph.new(@schema, { endpoint: endpoint })

        expect {
          graph.endpoint
        }.to raise_error(Errors::Graph::EndpointKeyNotFound)
      end
    end

    describe "#render" do
      it "returns its schema's data" do
        pull = { film: { id: UUID.generate } }
        @schema.stub({ render: pull })

        graph = Graph.new(@schema)
        graph.render.should == pull
      end

      it "returns a dottable hash" do
        pull = { film: { id: UUID.generate } }
        @schema.stub({ render: pull })

        graph = Graph.new(@schema)
        graph.render.should be_a(DottableHash)
      end

      it "sends interpolated endpoint to its schema" do
        endpoint = "http://endpoint.local/?:client_id"
        client_id = UUID.generate
        graph = Graph.new(@schema, { endpoint: endpoint, client_id: client_id })

        @schema.should_receive(:render).with({ endpoint: graph.endpoint }).and_return({})
        graph.render
      end

      context "with nested graphs" do
        before(:each) do
          film_schema = {
            title: "film",
            type: Object,
            properties: { director_id: { type: UUID } }
          }
          @film_schema = Schema.new(film_schema)
          @director_id = UUID.generate
          @film_schema.stub({ render: { film: { director_id: @director_id } } })

          director_schema = {
            title: "director",
            type: Object,
            properties: { id: { type: UUID } }
          }
          @director_schema = Schema.new(director_schema)
        end

        it "merges nested graphs" do
          pulled_data = { a: "attribute" }
          @director_schema.stub({ render: pulled_data })
          film = Graph.new(@film_schema, { graphs: [Graph.new(@director_schema)] })

          film = film.render
          film[:film].should include(pulled_data)
        end

        it "uses parent data to calculate endpoint" do
          film = Graph.new(@film_schema)
          relationships = { director_id: :id }
          endpoint = "http://endpoint.local/directors/:id"
          film.graphs << Graph.new(@director_schema, { endpoint: endpoint, relationships: relationships })

          @director_schema.should_receive(:render).with do |args|
            args[:endpoint].should == "http://endpoint.local/directors/#{@director_id}"
          end.and_return({})
          film.render
        end

        it "uses parent data to make multiple queries" do
          pending
          films_schema = Schema.new({ title: "films", type: Array, items: { properties: { id: { type: UUID } } } })
          film_graph = Graph.new(@film_schema, { relationships: { id: :id } })
          films = Graph.new(films_schema, { graphs: [film_graph] })
          films.render.film_.should be_a(Array)
        end

        it "uses parent data for childrens' properties when explicitly used" do
          relationships = { director_id: :id }
          director = Graph.new(@director_schema, { relationships: relationships })
          film = Graph.new(@film_schema, { graphs: [director] })

          film.render.film.director.id.should == @director_id
        end
      end
    end
  end
end
