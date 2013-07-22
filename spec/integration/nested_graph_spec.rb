require "representation"

describe Representation do
  before(:all) do
    Representation.load_schemas!(Helpers::SCHEMA_DIRECTORY)
  end

  after(:all) do
    Representation.schemas = {}
  end

  describe "request" do
    before(:each) do
      @films_endpoint = "http://films.local/films"
      @film_endpoint = "http://films.local/films/:id"
      @aquatic_id = UUID.generate
      @darjeeling_id = UUID.generate
    end

    it "returns structured data for nested queries" do
      stub_request(:get, @films_endpoint).to_return({ body: [{ id: @aquatic_id }, { id: @darjeeling_id }].to_json })

      aquatic_name = "The Life Aquatic with Steve Zissou"
      aquatic_uri = @film_endpoint.gsub(":id", @aquatic_id)
      stub_request(:get, aquatic_uri).to_return({ body: { name: aquatic_name }.to_json })

      darjeeling_name = "The Darjeeling Limited"
      darjeeling_uri = @film_endpoint.gsub(":id", @darjeeling_id)
      stub_request(:get, darjeeling_uri).to_return({ body: { name: darjeeling_name }.to_json })

      options = {
        graphs: [Representation::Graph.new(:film, { endpoint: @film_endpoint, relationships: { id: :id }})],
        endpoint: @films_endpoint
      }
      graph = Representation::Graph.new(:films, options)
      graph.pull.should == {
        films: [
          { name: aquatic_name, year: nil },
          { name: darjeeling_name, year: nil }
        ]
      }
    end
  end
end
