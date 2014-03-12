require "render"

module Render
  describe Graph do
    before(:all) do
      Render::Definition.load_from_directory!(Helpers::SCHEMA_DIRECTORY)

      @host = "films.local"
      @aquatic_id = UUID.generate
      @darjeeling_id = UUID.generate
      @aquatic_name = "The Life Aquatic with Steve Zissou"
      @darjeeling_name = "The Darjeeling Limited"
    end

    after(:all) do
      Render::Definition.instances.clear
    end

    it "uses first request's data for subsequent requests" do
      stub_request(:get, "http://films.local").to_return({ body: [{ id: @aquatic_id }, { id: @darjeeling_id }].to_json })
      stub_request(:get, "http://films.local/films/#{@aquatic_id}").to_return({ body: { name: @aquatic_name }.to_json })
      stub_request(:get, "http://films.local/films/#{@darjeeling_id}").to_return({ body: { name: @darjeeling_name }.to_json })

      graph = Render::Graph.new("films_index", { host: "films.local" })
      graph.graphs << Render::Graph.new("films_show", { host: "films.local", relationships: { id: :id } })
      response = graph.render!

      response.should == {
        films_index: [{ id: @aquatic_id }, { id: @darjeeling_id }],
        films_show: [
          { name: @aquatic_name, year: nil },
          { name: @darjeeling_name, year: nil }
        ]
      }
    end

    it "makes subsequent calls from simple array data" do
      stub_request(:get, "http://films.local").to_return({ body: [@aquatic_id, @darjeeling_id].to_json })
      stub_request(:get, "http://films.local/films/#{@aquatic_id}").to_return({ body: { name: @aquatic_name }.to_json })
      stub_request(:get, "http://films.local/films/#{@darjeeling_id}").to_return({ body: { name: @darjeeling_name }.to_json })

      schema = Render::Schema.new({
        title: :films_as_array_of_ids,
        type: Array,
        endpoint: "http://{host}",
        items: {
          type: UUID
        }
      })

      graph = Render::Graph.new(schema, { host: "films.local" })
      graph.graphs << Render::Graph.new("films_show", { host: "films.local", relationships: { id: :id } })
      response = graph.render!

      response.should == {
        films_as_array_of_ids: [@aquatic_id, @darjeeling_id],
        films_show: [
          { name: @aquatic_name, year: nil },
          { name: @darjeeling_name, year: nil }
        ]
      }
    end

  end
end
