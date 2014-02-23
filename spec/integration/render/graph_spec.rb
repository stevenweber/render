require "render"

module Render
  describe Graph do
    before(:each) do
      @schema = {
        title: :films,
        type: Array,
        items: {
          type: Object,
          properties: {
            id: { type: "number" }
          }
        }
      }
    end

    it "requests data from an endpoint" do
      stub_request(:get, "http://films.local").to_return({ body: [{ id: 1 }].to_json })

      response = Render::Graph.new(@schema, { endpoint: "http://films.local" }).render!
      response.should == { films: [{ id: 1 }] }
    end

    it "request data from endpoint with explicit values" do
      director_1s_films_request = stub_request(:get, "http://films.local/directors/1/films").to_return({ body: "{}" })
      @schema.merge!({ endpoint: "http://films.local/directors/:id/films" })

      response = Render::Graph.new(@schema, { id: 1 }).render!
      director_1s_films_request.should have_been_made.once
    end

    it "requests data from an endpoint specified in schema" do
      stub_request(:get, "http://films.local").to_return({ body: [{ id: 1 }].to_json })
      @schema.merge!({ endpoint: "http://films.local" })

      response = Render::Graph.new(@schema).render!
      response.should == { films: [{ id: 1 }] }
    end

    it "interpolates variables into endpoint" do
      stub_request(:get, "http://films.local").to_return({ body: [{ id: 1 }].to_json })
      @schema.merge!({ endpoint: "http://:host" })

      response = Render::Graph.new(@schema, { host: "films.local" }).render!
      response.should == { films: [{ id: 1 }] }
    end

    describe "testing" do
      before(:each) do
        @original_live = Render.live
        Render.live = false
      end

      after(:each) do
        Render.live = @original_live
      end

      it "creates fake data for testing" do
        schema = {
          title: :film,
          type: Object,
          properties: {
            id: { type: UUID },
            title: { type: String },
            director: {
              type: Object,
              properties: {
                name: { type: String },
                rating: { type: Float }
              }
            },
            genre: {
              type: String,
              enum: %w(horror action sci-fi)
            },
            tags: {
              type: Array,
              minItems: 1,
              items: {
                type: Object,
                properties: {
                  name: { type: String },
                  id: { type: Integer }
                }
              }
            }
          }
        }

        response = Render::Graph.new(schema).render!
        UUID.validate(response.film.id).should be_true
        response.film.title.should be_a(String)
        response.film.director.name.should be_a(String)
        response.film.director.rating.should be_a(Float)
        %w(horror action sci-fi).should include(response.film.genre)
        response.film.tags.first.name.should be_a(String)
        response.film.tags.first.id.should be_a(Integer)
      end

      it "allows overwriting fake data values" do
        schema = {
          title: :film,
          type: Object,
          properties: {
            id: { type: UUID },
            director: {
              type: Object,
              properties: {
                name: { type: String }
              }
            }
          }
        }

        her_name = "Kathryn Bigelow"
        response = Render::Graph.new(schema).render!({ director: { name: her_name } })
        response.film.director.name.should == her_name
      end
    end

  end
end
