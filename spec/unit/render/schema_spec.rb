require "render"

module Render
  describe Schema do
    describe "#initialize" do
      describe "#definition" do
        it "is set from argument" do
          schema_definition = { properties: {} }
          Schema.new(schema_definition).definition.should == schema_definition
        end

        it "is set to preloaded definition" do
          definition_title = :preloaded_schema
          definition = { title: definition_title, properties: { title: { type: String } } }
          Render.load_definition!(definition)
          Schema.new(definition_title).definition.should == definition
        end
      end

      it "sets its type from schema" do
        type = [Array, Object].sample
        definition = { type: type, properties: {}, items: {} }
        Schema.new(definition).type.should == type
      end

      describe "#array_attribute" do
        it "is set for array schemas" do
          archetype_schema = {
            type: Array,
            items: {
              type: String
            }
          }

          attribute = Schema.new(archetype_schema).array_attribute
          attribute.type.should == String
          attribute.archetype.should == true
        end
      end

      describe "#hash_attributes" do
        it "is set for object schemas" do
          simple_schema = {
            properties: {
              name: { type: String },
              genre: { type: String }
            }
          }

          schema = Schema.new(simple_schema)
          schema.hash_attributes.size.should == 2
          schema.hash_attributes.any? { |a| a.name == :name && a.type == String }.should == true
          schema.hash_attributes.any? { |a| a.name == :genre && a.type == String }.should == true
        end
      end
    end

    describe "#serialize" do
      it "returns data from hashes" do
        definition = {
          title: "film",
          type: Object,
          properties: {
            title: {
              type: String
            }
          }
        }
        data = { title: "a name" }
        Schema.new(definition).serialize(data).should == data
      end


      it "returns data from arrays" do
        definition = {
          title: "names",
          type: Array,
          items: {
            type: String
          }
        }
        schema = Schema.new(definition)
        names = ["bob", "bill"]
        schema.serialize(names).should == names
      end

      it "returns data from arrays of schemas" do
        definition = {
          title: "films",
          type: Array,
          items: {
            type: Object,
            properties: {
              id: { type: UUID }
            }
          }
        }

        the_id = UUID.generate
        films = [{ id: the_id }]
        schema = Schema.new(definition)
        schema.serialize(films).should == films
      end
    end
  end

  describe "#render" do
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

end
