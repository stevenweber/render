module Render
  describe Attribute do
    describe "#default_value" do
      before(:each) do
        Render.stub({ live: false })
      end

      describe "String" do
        it "uses attribute name for context" do
          name = "some identifier"
          faux_value = HashAttribute.new({ name => { type: String } }).default_value
          faux_value.should include(name)
        end
      end

      describe "#bias_type" do
        it "biases the format" do
          attribute = HashAttribute.new({ name: { type: String, format: UUID } })
          attribute.bias_type.should eq(UUID)
        end

        it "biases the first type" do
          attribute = HashAttribute.new({ name: { type: [String, Integer] } })
          attribute.bias_type.should eq(String)
        end
      end

    end
  end
end
