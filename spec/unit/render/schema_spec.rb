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
      it "returns serialized array" do
        definition = {
          type: Array,
          items: {
            type: UUID
          }
        }
        schema = Schema.new(definition)
        schema.array_attribute.should_receive(:serialize).with(nil).and_return([:data])
        schema.serialize.should == [:data]
      end

      it "returns serialized hash" do
        definition = {
          type: Object,
          properties: {
            title: { type: String }
          }
        }
        schema = Schema.new(definition)
        schema.hash_attributes.first.should_receive(:serialize).with(nil).and_return({ title: "foo" })
        schema.serialize.should == { title: "foo" }
      end
    end

    describe "#render" do
      context "live" do
        before(:all) do
          @original_defs = Render.definitions
          Render.load_definition!({
            title: :film,
            properties: {
              genre: { type: String }
            }
          })
        end

        after(:all) do
          Render.definitions = @original_defs
        end

        it "returns attribute data from endpoint" do
          endpoint = "http://endpoint.local"
          genre = "The Shining"
          data = { genre: genre }
          response = { status: 200, body: data.to_json }
          stub_request(:get, endpoint).to_return(response)

          schema = Schema.new(:film)
          schema.hash_attributes.first.should_receive(:serialize).with(genre).and_return({ genre: genre })

          schema.render({ endpoint: endpoint }).should == { film: data }
        end

        it "raises error if endpoint does not return a 2xx" do
          endpoint = "http://endpoint.local"
          stub_request(:get, endpoint).to_return({ status: 403 })

          expect {
            schema = Schema.new(:film)
            schema.render({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::RequestError)
        end

        it "returns meaningful error when response contains invalid JSON" do
          endpoint = "http://enpoint.local"
          stub_request(:get, endpoint).to_return({ body: "Server Error: 500" })

          expect {
            Schema.new(:film).render({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::InvalidResponse)
        end
      end

      context "faked" do
        before(:each) do
          Render.stub({ live: false })
        end

        it "returns schema with fake values" do
          definition = {
            title: :film,
            properties: {
              title: { type: String }
            }
          }
          schema = Schema.new(definition)
          film = schema.render[:film]
          film[:title].should be_a(String)
        end
      end

      it "handles responses that use definition title as root key" do
        definition = {
          title: :film,
          properties: {
            genre: { type: String }
          }
        }
        endpoint = "http://endpoint.local"
        data = { film: { genre: "the genre" } }
        response = { status: 200, body: data.to_json }
        stub_request(:get, endpoint).to_return(response)

        film = Schema.new(definition)
        film.render({ endpoint: endpoint }).should == data
      end

      it "handles Array responses" do
        definition = {
          title: :films,
          type: Array,
          items: {
            title: :film,
            properties: {
              name: { type: String }
            }
          }
        }
        schema = Schema.new(definition)

        endpoint = "http://endpoint.local"
        first_name = "The Shining"
        second_name = "Eyes Wide Shut"
        data = [
          { name: first_name },
          { name: second_name }
        ]
        stub_request(:get, endpoint).to_return({ status: 200, body: data.to_json })

        schema.render({ endpoint: endpoint }).should == { films: data }
      end
    end
  end
end
