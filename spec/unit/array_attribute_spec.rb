require "render/array_attribute"

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
        attribute = ArrayAttribute.new({ items: { format: UUID } })
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
        faux_data = @attribute.serialize
        faux_data.size.should be_between(0, ArrayAttribute::FAUX_DATA_UPPER_LIMIT)
        faux_data.sample.class.should == Float
      end
    end

  end
end
