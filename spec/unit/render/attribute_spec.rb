module Render
  describe Attribute do
    describe "#initialize" do
      describe "#name" do
        it "is set from options key" do
          options = { id: { type: UUID } }
          Attribute.new(options).name.should == :id
        end
      end

      describe "#type" do
        it "is set from options" do
          type = Integer
          attribute = Attribute.new({ type: type })
          attribute.type.should == type
        end

        it "is set from name hash" do
          type = String
          attribute = Attribute.new({ id: { type: UUID } })
          attribute.type.should == UUID
        end

        it "determines type from string" do
          Attribute.new({ type: "string" }).type.should == String
        end
      end

      describe "#schema" do
        it "is set to nil if its a regular attribute" do
          Attribute.new({ id: { type: UUID } }).schema.should == nil
        end

        it "is initiazed from options" do
          options = {
            film: {
              type: Object,
              properties: {
                year: { type: Integer }
              }
            }
          }

          schema = Attribute.new(options).schema
          schema.title.should == :film
          schema.type.should == Object
          properties = schema.properties
          properties.size.should == 1
          attribute = properties.first
          attribute.name.should == :year
          attribute.type.should == Integer
        end
      end

      context "enums" do
        it "sets enum values" do
          enum_values = ["foo", "bar", "baz"]
          attribute = Attribute.new({ type: String, enum: enum_values })
          attribute.enums.should == enum_values
        end
      end
    end

    describe "#to_hash" do
      it "converts properties to hashes" do
        properties = { foo: { type: String } }
        attribute = Attribute.new(properties)
        attribute.to_hash.should == { foo: nil }
      end

      it "converts properties to hashes with values" do
        properties = { foo: { type: String } }
        attribute = Attribute.new(properties)
        attribute.to_hash("bar").should == { foo: "bar" }
      end

      it "converts schema values to hashes" do
        schema_name = "foo"
        properties = {
          schema_name => {
            type: Object,
            properties: {
              attribute: { type: String }
            }
          }
        }

        value = "baz"
        data = { attribute: value }

        attribute = Attribute.new(properties)
        attribute.to_hash(data).should == { foo: { :attribute => value } }
      end
    end

    describe "#value" do
      context "offline mode" do
        before(:all) do
          @original_live = Render.live
          Render.live = false
        end

        after(:all) do
          Render.live = @original_live
        end

        it "generate value based on type" do
          supported_classes = [
            String,
            Integer
          ]

          supported_classes.each do |klass|
            Attribute.new({ type: klass }).default_value.should be_a(klass)
          end
          UUID.validate(Attribute.new({ type: UUID }).default_value).should be_true
        end

        it "generates value from enum" do
          enums = ["horror", "comedy", "drama"]
          attribute = Attribute.new({ genre: { enum: enums, type: String } })
          enums.should include(attribute.default_value)
        end
      end
    end

  end
end
