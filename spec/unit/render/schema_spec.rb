require "render"

module Render
  describe Schema do
    before(:each) do
      @film_schema = {
        title: "film",
        type: Object,
        properties: {
          name: { type: String },
          genre: { type: String }
        }
      }

      @films_schema = {
        title: "films",
        type: Array,
        items: {
          title: :film,
          properties: {
            name: { type: String },
            genre: { type: String }
          }
        }
      }

      @director_schema = {
        title: "director",
        type: Object,
        properties: {
          films: {
            type: Array,
            items: {
              type: Object,
              properties: {
                name: { type: String },
                year: { type: Integer }
              }
            }
          }
        }
      }
    end

    describe "#initialize" do
      it "sets schema from argument" do
        schema = { properties: {} }
        Schema.new(schema).schema.should == schema
      end

      it "sets schema from preloaded schemas" do
        schema = { title: :preloaded_schema, properties: { title: { type: String } } }
        Render.load_schema!(schema)
        Schema.new(:preloaded_schema).schema.should == schema
      end

      it "raises an error if preloaded schema cannot be found" do
        expect {
          Schema.new(:unloaded_schema)
        }.to raise_error(Render::Errors::Schema::NotFound)
      end

      it "sets its type from schema" do
        type = [Array, Object].sample
        schema = { type: type, properties: {} }
        Schema.new(schema).type.should == type
      end

      describe "#properties" do
        it "sets properties to schema attributes" do
          simple_schema = {
            properties: {
              name: { type: String },
              genre: { type: String }
            }
          }

          schema = Schema.new(simple_schema)
          schema.properties.size.should == 2
          schema.properties.any? { |a| a.name == :name && a.type == String }.should == true
          schema.properties.any? { |a| a.name == :genre && a.type == String }.should == true
        end

        it "sets properties to array of archetype attributes" do
          archetype_schema = {
            type: Array,
            items: {
              type: String
            }
          }

          properties = Schema.new(archetype_schema).properties
          properties.size.should == 1
          archetype = properties.first
          archetype.type.should == String
          archetype.archetype.should == true
        end

        it "sets properties to array of nested schemas" do
          array_schema = {
            type: Array,
            items: {
              type: Object,
              properties: {
                title: { type: String }
              }
            }
          }

          schema = Schema.new(array_schema)
          schema.properties.size.should == 1
          attribute = schema.properties.first
          attribute.schema.should be
          attribute.schema.properties.size.should == 1
          attribute.schema.properties.first.name.should == :title
        end
      end
    end

    describe "#pull" do
      context "live" do
        it "returns schema with values from endpoint" do
          endpoint = "http://endpoint.local"
          name = "The Shining"
          genre = "Horror"
          response_body = { film: { name: name, genre: genre } }
          response = { status: 200, body: response_body.to_json }
          stub_request(:get, endpoint).to_return(response)

          film = Schema.new(@film_schema)
          film.render({ endpoint: endpoint }).should == response_body
        end

        it "raises error if response is not 2xx" do
          endpoint = "http://endpoint.local"
          response = { status: 403, body: "OMGWTFBBQ" }
          stub_request(:get, endpoint).to_return(response)

          expect {
            film = Schema.new(@film_schema)
            film.render({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::RequestError)
        end

        it "returns meaningful error when response contains invalid JSON" do
          endpoint = "http://enpoint.local"
          stub_request(:get, endpoint).to_return({ body: "Server Error: 500" })

          expect {
            Schema.new(@film_schema).render({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::InvalidResponse)
        end
      end

      context "faked" do
        before(:each) do
          Render.stub({ live: false })
        end

        it "returns schema with fake values" do
          film = Schema.new(@film_schema)
          film = film.render[:film]
          film[:name].should be_a(String)
          film[:genre].should be_a(String)
        end
      end

      it "handles responses that do not use schema title as root key" do
        endpoint = "http://endpoint.local"
        response_body = { name: "the name", genre: "the genre" }
        response = { status: 200, body: response_body.to_json }
        stub_request(:get, endpoint).to_return(response)

        film = Schema.new(@film_schema)
        film.render({ endpoint: endpoint }).should == { film: response_body }
      end

      it "handles Array responses" do
        endpoint = "http://endpoint.local"
        first_name = "The Shining"
        second_name = "Eyes Wide Shut"
        genre = "Horror"

        response_body = [
          { name: first_name, genre: genre },
          { name: second_name, genre: genre }
        ]
        response = { status: 200, body: response_body.to_json }
        stub_request(:get, endpoint).to_return(response)

        film = Schema.new(@films_schema)
        film.render({ endpoint: endpoint }).should == { films: response_body }
      end
    end

    describe "#serialize" do
      it "returns parsed array items" do
        Render.stub({ live: false })
        director = Schema.new(@director_schema)

        kubrick = "Stanley Kubrick"
        first_film = "Flying Padre: An RKO-Pathe Screenliner"
        year = 1951
        data = {
          films: [{
              name: first_film,
              notInSchema: "experimental",
              year: year
          }]
        }

        director.serialize(data).should == {
          films: [{
            name: first_film,
            year: year
          }]
        }
      end

    end
  end
end
