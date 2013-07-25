module Render
  describe Attribute do
    context "generators" do
      before(:each) do
        @original_generators = Render.generators
        @original_live = Render.live
        Render.live = false
      end

      after(:each) do
        Render.generators = @original_generators
        Render.live = @original_live
      end

      it "uses matching generator for #faux_value" do
        name = "Canada Dry"
        generator = Generator.new({ type: String, matcher: %r{.*name.*}, algorithm: proc { name } })
        Render.generators << generator

        Attribute.new({ name: { type: String } }).default_value.should == name
      end

      it "uses really bare-boned type if no generator is found" do
        bare_boned_string = "A String"
        Attribute.new({ foo: { type: String } }).default_value.should == bare_boned_string
      end
    end
  end
end
