require "render/attributes/array_attribute"

module Render
  describe ArrayAttribute do
    describe "#initialize" do
      it "sets name to title for faux_value generators to match" do
        ArrayAttribute.new({ title: "ids", items: { type: UUID } }).name.should == :ids
      end

      describe "#format" do
        it "is set from options" do
          ArrayAttribute.new({ items: { type: String, format: UUID } }).format.should == UUID
        end

        it "is nil for indeterminable types" do
          ArrayAttribute.new({ items: { type: String, format: "random-iso-format" } }).format.should == nil
        end
      end
    end

    describe "archetype" do
      it "returns only a value" do
        id = UUID.generate
        attribute = ArrayAttribute.new({ items: { type: UUID } })
        attribute.serialize([id]).should == [id]
      end
    end

    describe "#serialize" do
      it "returns value as defined type" do
        attribute = ArrayAttribute.new({ items: { type: Float } })
        attribute.serialize(["2.0"]).should == [2.0]
      end

      it "returns faux value as defined type" do
        Render.stub({ live: false })

        attribute = ArrayAttribute.new({ items: { type: Float }, maxItems: 1, minItems: 1 })
        attribute.stub({ default_value: "2" })

        attribute.serialize.should == [2.0]
      end

      it "enforces uniqueness" do
        attribute = ArrayAttribute.new({ items: { type: Integer }, uniqueItems: true })
        attribute.serialize(["2.0", 2, "2"]).should == [2]
      end

      it "does not enforce uniqueness" do
        attribute = ArrayAttribute.new({ items: { type: Integer } })
        attribute.serialize(["2.0", 2, "2"]).should == [2, 2, 2]
      end
    end

    describe "#faux_data" do
      before(:each) do
        Render.stub({ live: false })
        @lower_limit = 6
        @attribute = ArrayAttribute.new({ items: { type: Float }, minItems: @lower_limit })
      end

      it "uses explicit value for faux data" do
        explicit_data = [rand(10.0)]
        @attribute.serialize(explicit_data).should == explicit_data
      end

      it "generates fake number of elements" do
        upper_limit = 9
        stub_const("Render::ArrayAttribute::FAUX_DATA_UPPER_LIMIT", upper_limit)

        faux_data = @attribute.serialize
        faux_data.size.should >= @lower_limit
        faux_data.size.should <= upper_limit
        faux_data.sample.class.should == Float
      end
    end

  end
end
