require "render"

describe Render do
  before(:all) do
    Render.load_definitions!(Helpers::SCHEMA_DIRECTORY)
  end

  after(:all) do
    Render.definitions = {}
  end

  describe "request" do
    before(:each) do
      @films_endpoint = "http://films.local/films"
      @film_endpoint = "http://films.local/films/:id"
      @aquatic_id = UUID.generate
      @darjeeling_id = UUID.generate
      @aquatic_name = "The Life Aquatic with Steve Zissou"
      @darjeeling_name = "The Darjeeling Limited"
    end

    it "returns structured data for nested queries" do
      films_index_response = [{ id: @aquatic_id }, { id: @darjeeling_id }]
      stub_request(:get, @films_endpoint).to_return({ body: films_index_response.to_json })

      aquatic_name = "The Life Aquatic with Steve Zissou"
      aquatic_uri = @film_endpoint.gsub(":id", @aquatic_id)
      stub_request(:get, aquatic_uri).to_return({ body: { name: aquatic_name }.to_json })

      darjeeling_name = "The Darjeeling Limited"
      darjeeling_uri = @film_endpoint.gsub(":id", @darjeeling_id)
      stub_request(:get, darjeeling_uri).to_return({ body: { name: darjeeling_name }.to_json })

      options = {
        graphs: [Render::Graph.new(:films_show, { endpoint: @film_endpoint, relationships: { id: :id }})],
        endpoint: @films_endpoint
      }
      graph = Render::Graph.new(:films_index, options)
      graph.render!.should == {
        films_index: {
          films: films_index_response
        },
        films_show: [
          { film: { name: aquatic_name, year: nil } },
          { film: { name: darjeeling_name, year: nil } }
        ]
      }
      graph.rendered_data.films_show.first.film.name.should == aquatic_name
    end

    it "makes subsequent calls from archetype array data" do
      stub_request(:get, @films_endpoint).to_return({ body: [@aquatic_id, @darjeeling_id].to_json })

      aquatic = @film_endpoint.gsub(":id", @aquatic_id)
      stub_request(:get, aquatic).to_return({ body: { name: @aquatic_name }.to_json })

      darjeeling = @film_endpoint.gsub(":id", @darjeeling_id)
      stub_request(:get, darjeeling).to_return({ body: { name: @darjeeling_name }.to_json })

      films = Render::Schema.new({
        title: :films,
        type: Array,
        items: {
          type: UUID
        }
      })

      film = Render::Schema.new({
        title: :film,
        type: Object,
        properties: {
          name: { type: String }
        }
      })

      films = Render::Graph.new(films, { endpoint: @films_endpoint })
      films.graphs << Render::Graph.new(film, { endpoint: @film_endpoint, relationships: { id: :id } })
      films.render!.film.should =~ [
        { name: @aquatic_name },
        { name: @darjeeling_name }
      ]
    end

  end
end
