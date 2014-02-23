module Render
  describe HashAttribute do
    describe "#initialize" do
      describe "#name" do
        it "is set from options key" do
          options = { id: { type: UUID } }
          HashAttribute.new(options).name.should == :id
        end
      end

      describe "#type" do
        it "is set from options" do
          type = Integer
          attribute = HashAttribute.new({ key_name: { type: type } })
          attribute.type.should == type
        end

        it "is set from name hash" do
          type = String
          attribute = HashAttribute.new({ id: { type: UUID } })
          attribute.type.should == UUID
        end

        it "determines type from string" do
          HashAttribute.new({ key_name: { type: "string" } }).type.should == String
        end
      end

      describe "#format" do
        it "is set from options" do
          HashAttribute.new({ key_name: { type: String, format: UUID } }).format.should == UUID
        end

        it "is nil for indeterminable types" do
          HashAttribute.new({ key_name: { type: String, format: "random-iso-format" } }).format.should == nil
        end
      end

      describe "#schema" do
        it "is set to nil if its a regular attribute" do
          HashAttribute.new({ id: { type: UUID } }).schema.should == nil
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

          schema = HashAttribute.new(options).schema
          schema.title.should == :film
          schema.type.should == Object
          hash_attributes = schema.hash_attributes
          hash_attributes.size.should == 1
          attribute = hash_attributes.first
          attribute.name.should == :year
          attribute.type.should == Integer
        end
      end

      context "enums" do
        it "sets enum values" do
          enum_values = ["foo", "bar", "baz"]
          attribute = HashAttribute.new({ key: { type: String, enum: enum_values } })
          attribute.enums.should == enum_values
        end
      end
    end

    describe "#serialize" do
      it "returns attribute with its value" do
        attribute = HashAttribute.new({ title: { type: String } })
        title = "the title"
        attribute.serialize(title).should == { title: title }
      end

      describe "nested schema" do
        it "returns serialized schema" do
          attribute = HashAttribute.new({ film: { type: Object, properties: { title: { type: String } } } })
          title = "the title"
          attribute.serialize({ title: title }).should == { film: { title: title } }
        end
      end

      it "returns value as defined type" do
        attribute = HashAttribute.new({ year: { type: Integer } })
        attribute.serialize("2").should == { year: 2 }
      end

      it "returns faux value as defined type" do
        attribute = HashAttribute.new({ year: { type: Integer } })
        attribute.stub({ default_value: "2" })

        attribute.serialize(nil).should == { year: 2 }
      end

      context "offline" do
        before(:each) do
          Render.stub({ live: false })
        end

        it "uses faux data when offline" do
          type = [String, Integer].sample
          data = HashAttribute.new({ title: { type: type } }).serialize(nil)
          data[:title].should be_a(type)
        end

        it "maintains nil values when instructed" do
          data = HashAttribute.new({ title: { type: Integer } }).serialize(nil, true)
          data[:title].should == nil
        end
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
            HashAttribute.new({ key: { type: klass } }).default_value.should be_a(klass)
          end

          value = HashAttribute.new({ key: { type: UUID } }).default_value
          UUID.validate(value).should be_true
        end

        it "generates value from enum" do
          enums = ["horror", "comedy", "drama"]
          attribute = HashAttribute.new({ genre: { enum: enums, type: String } })
          enums.should include(attribute.default_value)
        end
      end
    end

  end
end
