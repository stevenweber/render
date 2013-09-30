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

    describe "#serialize" do
      it "returns attribute with its value" do
        attribute = Attribute.new({ title: { type: String } })
        title = "the title"
        attribute.serialize(title).should == { title: title }
      end

      describe "archetype" do
        it "returns only a value" do
          id = UUID.generate
          attribute = Attribute.new({ format: UUID })
          attribute.serialize(id).should == id
        end
      end

      describe "nested schema" do
        it "returns serialized schema" do
          attribute = Attribute.new({ film: { type: Object, properties: { title: { type: String } } } })
          title = "the title"
          attribute.serialize({ title: title }).should == { film: { title: title } }
        end
      end

      it "uses faux data when offline" do
        type = [String, Integer].sample
        Render.stub({ live: false })

        data = Attribute.new({ title: { type: type } }).serialize(nil)
        data[:title].should be_a(type)
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
