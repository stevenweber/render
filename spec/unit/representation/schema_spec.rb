require "representation"

module Representation
  describe Schema do
    before(:each) do
      @film_schema = {
        title: "film",
        type: Object,
        attributes: {
          name: { type: String },
          genre: { type: String }
        }
      }

      @films_schema = {
        title: "films",
        type: Array,
        elements: {
          title: :film,
          attributes: {
            name: { type: String },
            genre: { type: String }
          }
        }
      }

      @director_schema = {
        title: "director",
        type: Object,
        attributes: {
          films: {
            type: Array,
            elements: {
              type: Object,
              attributes: {
                name: { type: String },
                year: { type: Integer }
              }
            }
          }
        }
      }
    end

    describe "#initialize" do
      describe "#schema" do
        before(:each) do
          @schema = { attributes: {} }
        end

        it "is set to hash argument" do
          Schema.new(@schema).schema.should == @schema
        end

        it "is set to preloaded schema" do
          Representation.stub({ schemas: { film: @schema } })
          Schema.new(:film).schema.should == @schema
        end

        it "raises an error if preloaded schema cannot be found" do
          expect {
            Schema.new(:unloaded_schema)
          }.to raise_error(Representation::Errors::Schema::NotFound)
        end
      end

      it "sets title from schema" do
        title = "films"
        schema = { title: title, attributes: {} }
        Schema.new(schema).title.should == title
      end

      describe "#type" do
        it "is set from schema" do
          type = [Array, Object].sample
          schema = { type: type, attributes: {} }
          Schema.new(schema).type.should == type
        end

        it "is parsed from string" do
          schema = { type: "string", attributes: {} }
          Schema.new(schema).type.should == String
        end
      end

      describe "#attributes" do
        it "is set with simple Attributes" do
          simple_schema = {
            attributes: {
              name: { type: String },
              genre: { type: String }
            }
          }

          schema = Schema.new(simple_schema)
          schema.attributes.size.should == 2
          schema.attributes.any? { |a| a.name == :name && a.type == String }.should == true
          schema.attributes.any? { |a| a.name == :genre && a.type == String }.should == true
        end

        it "is set with array archetypes" do
          archetype_schema = {
            elements: {
              type: String
            }
          }

          attributes = Schema.new(archetype_schema).attributes
          attributes.size.should == 1
          attributes.first.type.should == String
        end

        it "is set with schema-Attributes" do
          nested_schema = {
            attributes: {
              film: {
                type: Object,
                attributes: {
                  name: { type: String }
                }
              }
            }
          }

          schema = Schema.new(nested_schema)
          schema.attributes.size.should == 1
          schema.attributes.first.schema.should be
        end

        it "is set with array-Attributes" do
          array_schema = {
            elements: {
              film: {
                type: Object,
                attributes: {
                  name: { type: String }
                }
              }
            }
          }
          schema = Schema.new(array_schema)
          schema.attributes.size.should == 1
          schema.attributes.first.schema.should be
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
          film.pull({ endpoint: endpoint }).should == response_body
        end

        it "raises error if response is not 2xx" do
          endpoint = "http://endpoint.local"
          response = { status: 403, body: "OMGWTFBBQ" }
          stub_request(:get, endpoint).to_return(response)

          expect {
            film = Schema.new(@film_schema)
            film.pull({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::RequestError)
        end

        it "returns meaningful error when response contains invalid JSON" do
          endpoint = "http://enpoint.local"
          stub_request(:get, endpoint).to_return({ body: "Server Error: 500" })

          expect {
            Schema.new(@film_schema).pull({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::InvalidResponse)
        end
      end

      context "faked" do
        before(:each) do
          Representation.stub({ live: false })
        end

        it "returns schema with fake values" do
          film = Schema.new(@film_schema)
          film = film.pull[:film]
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
        film.pull({ endpoint: endpoint }).should == { film: response_body }
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
        film.pull({ endpoint: endpoint }).should == { films: response_body }
      end
    end

    describe "#serialize" do
      it "returns parsed array elements" do
        Representation.stub({ live: false })
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
