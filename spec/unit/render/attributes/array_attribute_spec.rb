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

    describe "#faux_data" do
      before(:each) do
        Render.stub({ live: false })
        @attribute = ArrayAttribute.new({ items: { type: Float, required: true } })
      end

      it "uses explicit value for faux data" do
        explicit_data = [rand(10.0)]
        @attribute.serialize(explicit_data).should == explicit_data
      end

      it "generates fake number of elements" do
        lower_limit = 6
        upper_limit = 9
        @attribute.stub({ lower_limit: lower_limit })
        stub_const("Render::ArrayAttribute::FAUX_DATA_UPPER_LIMIT", upper_limit)

        faux_data = @attribute.serialize
        faux_data.size.should >= lower_limit
        faux_data.size.should <= upper_limit
        faux_data.sample.class.should == Float
      end
    end

  end
end
