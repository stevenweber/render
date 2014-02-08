# encoding: utf-8
require "render/graph"
require "uuid"

module Render
  describe Graph do
    before(:each) do
      Render.stub({ live: false })
      @definition = double(:definition)
      @schema = double(:schema, { type: Hash })
      Schema.stub(:new).with(@definition).and_return(@schema)
    end

    describe ".initialize" do
      describe "#schema" do
        it "is set from argument" do
          Schema.unstub(:new)
          schema = Schema.new({ title: :foo, properties: { name: { type: String } } })
          Graph.new(schema).schema.should == schema
        end

        it "is set to new Schema from definition" do
          Schema.should_receive(:new).with(:title_or_definition).and_return(:schema)
          Graph.new(:title_or_definition).schema.should == :schema
        end
      end

      it "sets attributes from options" do
        relationships = { director_id: :id }
        graphs = [double(:graph)]
        graph = Graph.new(@definition, {
          relationships: relationships,
          graphs: graphs,
        })

        graph.relationships.should == relationships
        graph.graphs.should == graphs
      end

      it "sets config from options that are not attributes" do
        relationships = { some: :relationship }
        client_id = UUID.generate
        graph = Graph.new(@definition, {
          relationships: relationships,
          client_id: client_id
        })

        graph.config.should == { client_id: client_id }
      end
    end

    describe ".endpoint" do
      it "returns #raw_endpoint" do
        simple_endpoint = "http://endpoint.local"
        graph = Graph.new(@definition, { endpoint: simple_endpoint })
        graph.endpoint.should == simple_endpoint
      end

      it "interpolates inherited parameters" do
        director_id = UUID.generate
        endpoint = "http://endpoint.local/directors/:id"
        relationships = { director_id: :id }

        graph = Graph.new(@definition, { endpoint: endpoint, relationships: relationships })
        graph.inherited_data = { director_id: director_id }

        graph.endpoint.should == "http://endpoint.local/directors/#{director_id}"
      end

      it "interpolates config options" do
        client_id = UUID.generate
        endpoint = "http://endpoint.local/?:client_id"

        graph = Graph.new(@definition, { endpoint: endpoint, client_id: client_id })
        graph.endpoint.should == "http://endpoint.local/?client_id=#{client_id}"
      end

      it "raises an error if no value can be found" do
        endpoint = "http://endpoint.com/?:undefined_key"
        graph = Graph.new(@definition, { endpoint: endpoint })

        expect {
          graph.endpoint
        }.to raise_error(Errors::Graph::EndpointKeyNotFound)
      end
    end

    describe "#render" do
      it "returns its schema's data" do
        serialized_data = { id: UUID.generate }
        pull = { film: serialized_data }
        @schema.stub({ render!: pull, serialized_data: serialized_data })

        graph = Graph.new(@definition)
        graph.render!.should == pull
      end

      it "returns a dottable hash" do
        pull = { film: { id: UUID.generate } }
        @schema.stub({ render!: pull })

        graph = Graph.new(@definition)
        graph.render!.should be_a(Extensions::DottableHash)
      end

      it "sends interpolated endpoint to its schema" do
        endpoint = "http://endpoint.local/?:client_id"
        client_id = UUID.generate
        graph = Graph.new(@definition, { endpoint: endpoint, client_id: client_id })

        @schema.should_receive(:render!).with(anything, graph.endpoint).and_return({})
        graph.render!
      end

      context "with nested graphs" do
        before(:each) do
          Schema.unstub(:new)
          film_definition = {
            title: "film",
            type: Object,
            properties: { director_id: { type: UUID } }
          }
          @film_schema = Schema.new(film_definition)

          @director_id = UUID.generate
          director_definition = {
            title: "director",
            type: Object,
            properties: { id: { type: UUID } }
          }
          @director_schema = Schema.new(director_definition)
        end

        it "includes nested graphs" do
          film = Graph.new(@film_schema, { graphs: [Graph.new(@director_schema)] })
          film = film.render!
          film.keys.should =~ [:film, :director]
        end

        it "uses parent data to calculate endpoint" do
          film = Graph.new(@film_schema)
          relationships = { director_id: :id }
          endpoint = "http://endpoint.local/directors/:id"
          film.graphs << Graph.new(@director_schema, { endpoint: endpoint, relationships: relationships })

          film_data = { director_id: @director_id }
          @film_schema.should_receive(:render!).and_yield(film_data).and_return(film_data)

          endpoint = "http://endpoint.local/directors/#{@director_id}"
          @director_schema.should_receive(:render!).with(anything, endpoint).and_return({})
          film.render!
        end

        it "uses parent data to make multiple queries" do
          films_schema = Schema.new({
            title: "films",
            type: Array,
            items: {
              properties: {
                id: { type: UUID }
              }
            }
          })

          film_graph = Graph.new(@film_schema, { relationships: { id: :director_id } })
          films = Graph.new(films_schema, { graphs: [film_graph] })

          first_film_id = UUID.generate
          second_film_id = UUID.generate
          films_response = [{ id: first_film_id }, { id: second_film_id }]
          films_schema.should_receive(:render!).and_yield(films_response).and_return({ films: films_response })

          response = films.render!
          response.film.should be_a(Array)
          response.film.should =~ [{ director_id: first_film_id }, { director_id: second_film_id }]
        end

        it "uses parent data for childrens' properties when explicitly used" do
          director = Graph.new(@director_schema, { relationships: { director_id: :id } })
          film = Graph.new(@film_schema, { graphs: [director] })
          @film_schema.should_receive(:render!).and_yield({ director_id: @director_id }).and_return({})

          film.render!.director.id.should == @director_id
        end

        it "uses archetype parental data" do
          films_schema = Schema.new({
            title: "films",
            type: Array,
            items: {
              type: UUID
            }
          })

          film_graph = Graph.new(@film_schema, { relationships: { anything: :director_id } })
          films = Graph.new(films_schema, { graphs: [film_graph] })

          film_id = UUID.generate
          films_response = [film_id]
          films_schema.should_receive(:render!).and_yield(films_response).and_return({ films: films_response })

          response = films.render!
          response.film.should be_a(Array)
          response.film.should =~ [{ director_id: film_id }]
        end
      end
    end
  end
end
