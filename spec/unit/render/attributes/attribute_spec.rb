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
    end
  end
end
