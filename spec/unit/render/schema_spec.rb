require "render"

module Render
  describe Schema do
    before(:each) do
      @original_defs = Definition.instances.dup
    end

    after(:each) do
      Definition.instances = @original_defs
    end

    describe "#initialize" do
      describe "#definition" do
        it "is set from argument" do
          schema_definition = { properties: {} }
          Schema.new(schema_definition).definition.should == schema_definition
        end

        it "is set to preloaded definition" do
          definition_id = :preloaded_schema
          definition = { id: definition_id, properties: { title: { type: String } } }
          Definition.load!(definition)

          Schema.new(definition_id).definition.should == definition
        end

        it "raises an error if definition is not found and argument is not a schema" do
          expect {
            Schema.new(:does_not_exists)
          }.to raise_error(Errors::Definition::NotFound)
        end

        # This is probably not the best form
        describe "non-container definitions" do
          it "creates Object container for subschemas" do
            non_container_definition = {
              students: { type: Array, items: { type: String } },
              teacher: { type: Object, properties: { name: { type: String } } }
            }

            converted_definition = {
              type: Object,
              properties: {
                students: { type: Array, items: { type: String } },
                teacher: { type: Object, properties: { name:  { type: String } } }
              }
            }

            non_container_schema = Schema.new(non_container_definition)
            converted_schema = Schema.new(converted_definition)
            non_container_schema.definition.should == converted_schema.definition
          end
        end
      end

      it "sets its type from schema" do
        type = [Array, Object].sample
        definition = { type: type, properties: {}, items: {} }
        Schema.new(definition).type.should == type
      end

      it "defaults its type to Object" do
        definition = { properties: {} }
        Schema.new(definition).type.should == Object
      end

      describe "#array_attribute" do
        it "is set for array schemas" do
          simple_schema = {
            type: Array,
            items: {
              type: String
            }
          }

          attribute = Schema.new(simple_schema).array_attribute
          attribute.types.should == [String]
          attribute.simple.should == true
        end
      end

      describe "#hash_attributes" do
        it "is set for object schemas" do
          simple_schema = {
            type: Object,
            properties: {
              name: { type: String },
              genre: { type: String }
            }
          }

          schema = Schema.new(simple_schema)
          schema.hash_attributes.size.should == 2
          schema.hash_attributes.any? { |a| a.name == :name && a.types == [String] }.should == true
          schema.hash_attributes.any? { |a| a.name == :genre && a.types == [String] }.should == true
        end
      end

      describe "$ref" do
        before(:each) do
          @original_instances = Definition.instances.dup
        end

        after(:each) do
          Definition.instances = @original_instances
        end

        it "creates subschemas for absolute references" do
          topping_definition = {
            id: "http://pizzas.local/schema#topping",
            type: Object, properties: { name: { type: String } }
          }
          Definition.load!(topping_definition)

          pizza_definition = {
            type: Object,
            properties: {
              toppings: { type: Array, items: { :$ref => "http://pizzas.local/schema#topping" } }
            }
          }
          pizza_schema = Schema.new(pizza_definition)

          pizza_schema.definition.should == {
            type: Object,
            properties: {
              toppings: {
                type: Array,
                items: {
                  id: "http://pizzas.local/schema#topping",
                  type: Object,
                  properties: { name: { type: String } }
                }
              }
            }
          }
        end

        it "interpolates definitions from foreign schema" do
          foreign_definition = {
            id: "http://foreign.com/foo#",
            type: Object,
            properties: {
              title: { type: String }
            }
          }
          Definition.load!(foreign_definition)

          definition = {
            type: Object,
            properties: {
              :$ref => "http://foreign.com/foo#properties"
            }
          }
          schema = Schema.new(definition)
          schema.definition.should == {
            type: Object,
            properties: {
              title: { type: String }
            }
          }
        end

        it "creates subschemas for relative references from root" do
          definition = {
            definitions: {
              address: {
                type: Object,
                properties: { number: { type: Integer } }
              }
            },
            type: Object,
            properties: {
              address: { :$ref => "#/definitions/address" }
            }
          }
          schema = Schema.new(definition)

          schema.definition[:properties].should == {
            address: {
              type: Object,
              properties: { number: { type: Integer } }
            }
          }
        end

        it "creates nested subschemas for relative references from root" do
          definition = {
            definitions: {
              address: {
                type: Object,
                properties: { number: { type: Integer } }
              }
            },
            type: Object,
            properties: {
              primary_location: {
                type: Object,
                properties: {
                  address: { :$ref => "#/definitions/address" }
                }
              }
            }
          }
          schema = Schema.new(definition)

          schema.definition[:properties].should == {
            primary_location: {
              type: Object,
              properties: {
                address: {
                  type: Object,
                  properties: {
                    number: { type: Integer }
                  }
                }
              }
            }
          }
        end

        it "interpolates closest relative definition" do
          definition = {
            definitions: { year: { type: :number } },
            type: Object,
            properties: {
              book: {
                definitions: { year: { type: Integer } },
                type: Object,
                properties: {
                  year: { :$ref => "definitions/year" }
                }
              }
            }
          }

          parsed_definition = Schema.new(definition).definition
          year_schema = parsed_definition.fetch(:properties).fetch(:book).fetch(:properties).fetch(:year)
          year_schema.fetch(:type).should == Integer
        end

        it "interpolates root-relative definition when specified" do
          definition = {
            definitions: { year: { type: :number } },
            type: Object,
            properties: {
              book: {
                definitions: { year: { type: Integer } },
                type: Object,
                properties: {
                  year: { :$ref => "#/definitions/year" }
                }
              }
            }
          }

          parsed_definition = Schema.new(definition).definition
          parsed_definition.fetch(:properties).fetch(:book).fetch(:properties).fetch(:year).fetch(:type).should == :number
        end

        it "expands to empty schema if no ref is found" do
          definition = {
            type: Object,
            properties: {
              year_relative: { :$ref => "definitions/year" },
              year_root: { :$ref => "#/definitions/year" }
            }
          }

          Schema.new(definition).definition.fetch(:properties).fetch(:year_relative).should == {}
          Schema.new(definition).definition.fetch(:properties).fetch(:year_root).should == {}
        end
      end
    end

    describe "#serialize!" do
      it "returns serialized array" do
        definition = {
          type: Array,
          items: {
            type: UUID
          }
        }
        schema = Schema.new(definition)
        schema.array_attribute.should_receive(:serialize).with(nil).and_return([:data])
        schema.serialize!.should == [:data]
      end

      it "returns serialized hash" do
        definition = {
          type: Object,
          properties: {
            title: { type: String }
          }
        }
        schema = Schema.new(definition)
        schema.hash_attributes.first.should_receive(:serialize).with(nil, anything).and_return({ title: "foo" })
        schema.serialize!.should == { title: "foo" }
      end
    end

    describe "#render!" do
      before(:each) do
        Definition.load!({
          id: :film,
          type: Object,
          properties: {
            genre: { type: String }
          }
        })
      end

      context "request" do
        it "raises error if endpoint does not return a 2xx" do
          endpoint = "http://endpoint.local"
          stub_request(:get, endpoint).to_return({ status: 403 })

          expect {
            schema = Schema.new(:film)
            schema.render!(nil, endpoint)
          }.to raise_error(Errors::Schema::RequestError)
        end

        it "returns meaningful error when response contains invalid JSON" do
          endpoint = "http://enpoint.local"
          stub_request(:get, endpoint).to_return({ body: "Server Error: 500" })

          expect {
            Schema.new(:film).render!(nil, endpoint)
          }.to raise_error(Errors::Schema::InvalidResponse)
        end

        it "uses configured request logic"
      end

      context "return value" do
        it "is serialized data" do
          endpoint = "http://endpoint.local"
          genre = "The Shining"
          data = { genre: genre }
          response = { status: 200, body: data.to_json }
          stub_request(:get, endpoint).to_return(response)

          schema = Schema.new(:film)
          schema.hash_attributes.first.should_receive(:serialize).with(genre, anything).and_return({ genre: genre })

          schema.render!(nil, endpoint).should == data
        end
      end

    end
  end
end
