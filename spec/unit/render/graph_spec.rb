# encoding: utf-8
require "render/graph"
require "uuid"

module Render
  describe Graph do
    before(:each) do
      @schema = double(:schema)
    end

    describe ".initialize" do
      it "has defaults" do
        graph = Graph.new(@schema)
        graph.raw_endpoint.should == ""
        graph.relationships.should == {}
        graph.graphs.should == []
        graph.parental_params.should == {}
        graph.config.should == {}
      end

      describe "schema" do
        it "sets argument" do
          graph = Graph.new(@schema)
          graph.schema.should == @schema
        end

        it "creates new schema from symbol (for loaded schema lookup)" do
          Schema.should_receive(:new).with(:film).and_return(:new_schema)
          Graph.new(:film).schema.should == :new_schema
        end
      end

      it "sets attributes" do
        relationships = { director_id: :id }
        graphs = [double(:graph)]
        graph = Graph.new(@schema, {
          relationships: relationships,
          graphs: graphs,
        })

        graph.relationships.should == relationships
        graph.graphs.should == graphs
      end

      it "treats non-used attributes as config" do
        relationships = { some: :relationship }
        graphs = [double(:some_graph)]
        client_id = UUID.generate
        graph = Graph.new(@schema, {
          relationships: relationships,
          graphs: graphs,
          client_id: client_id
        })

        graph.config.should == { client_id: client_id }
      end

      describe "#raw_endpoint" do
        it "is set with endpoint" do
          endpoint = "http://endpoint.local"
          graph = Graph.new(@schema, { endpoint: endpoint })
          graph.raw_endpoint.should == endpoint
        end
      end

      it "initializes params from endpoint" do
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

      it "interpolates parental_params" do
        director_id = UUID.generate
        endpoint = "http://endpoint.local/directors/:id"
        interpolated_endpoint = "http://endpoint.local/directors/#{director_id}"

        relationships = { director_id: :id }
        graph = Graph.new(@schema, { endpoint: endpoint, relationships: relationships })
        graph.parental_params[:id] = director_id

        graph.endpoint.should == interpolated_endpoint
      end

      it "interpolates config attributes" do
        client_id = UUID.generate
        endpoint = "http://endpoint.local/?:client_id"
        interpolated_endpoint = "http://endpoint.local/?client_id=#{client_id}"

        graph = Graph.new(@schema, { endpoint: endpoint, client_id: client_id })
        graph.endpoint.should == interpolated_endpoint
      end

      it "interpolates multiple path and query values" do
        the_shinning = UUID.generate
        kubrick = UUID.generate
        client_id = UUID.generate
        client_secret = UUID.generate

        endpoint = "http://endpoint.local/directors/:id/films/:film_id?:client_id&:client_secret"
        interpolated_endpoint = "http://endpoint.local/directors/#{kubrick}/films/#{the_shinning}?client_id=#{client_id}&client_secret=#{client_secret}"

        graph = Graph.new(@schema, { endpoint: endpoint, client_id: client_id, client_secret: client_secret })
        graph.parental_params = { id: kubrick, film_id: the_shinning }

        graph.endpoint.should == interpolated_endpoint
      end

      it "raises an error if no value can be found" do
        endpoint = "http://endpoint.com/?:undefined_key"
        graph = Graph.new(@schema, { endpoint: endpoint })

        expect {
          graph.endpoint
        }.to raise_error(Errors::Graph::EndpointKeyNotFound)
      end
    end

    describe ".render" do
      it "returns its schema's data" do
        pull = { film: { id: UUID.generate } }
        @schema.stub({ pull: pull })

        graph = Graph.new(@schema)
        graph.render.should == pull
      end

      it "sends interpolated endpoint to its schema" do
        endpoint = "http://endpoint.local/?:client_id"
        client_id = UUID.generate
        graph = Graph.new(@schema, { endpoint: endpoint, client_id: client_id })

        @schema.should_receive(:pull).with({ endpoint: graph.endpoint }).and_return(@pull)
        graph.render.should == @pull
      end

      context "with nested graphs" do
        before(:each) do
          Render.stub({ live: false })

          director_schema = {
            title: "director",
            type: Object,
            attributes: { id: { type: UUID } }
          }
          @director_schema = Schema.new(director_schema)

          film_schema = {
            title: "film",
            type: Object,
            attributes: { director_id: { type: UUID } }
          }
          @film_schema = Schema.new(film_schema)
        end

        it "merges nested graphs" do
          pulled_data = { a: "attribute" }
          @director_schema.stub({ pull: pulled_data })

          director = Graph.new(@director_schema)
          film = Graph.new(@film_schema, { graphs: [director]})

          film_graph = film.render[@film_schema.title.to_sym]
          film_graph.should include(pulled_data)
        end

        it "uses parent data to calculate endpoint" do
          director_id = UUID.generate
          film = Graph.new(@film_schema)
          film.schema.stub({ pull: { film: { director_id: director_id } } })

          endpoint = "http://endpoint.local/directors/:id"
          interpolated_endpoint = "http://endpoint.local/directors/#{director_id}"
          relationships = { director_id: :id }
          director = Graph.new(@director_schema, { endpoint: endpoint, relationships: relationships })

          film.graphs << director
          director.schema.should_receive(:pull).with do |args|
            args[:endpoint].should == interpolated_endpoint
          end.and_return({})

          film.render
        end

        context "offline" do
          it "uses parent data for childrens attributes" do
            relationships = { director_id: :id }
            director = Graph.new(@director_schema, { relationships: relationships })
            film = Graph.new(@film_schema, { graphs: [director]})

            film_graph = film.render[@film_schema.title.to_sym]
            film_graph[@director_schema.title.to_sym][:id].should == film_graph[:director_id]
          end
        end
      end
    end
  end
end
