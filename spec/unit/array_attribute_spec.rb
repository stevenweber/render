require "render/array_attribute"

module Render
  describe ArrayAttribute do
    describe "archetype" do
      it "returns only a value" do
        id = UUID.generate
        attribute = ArrayAttribute.new({ items: { format: UUID } })
        attribute.serialize([id]).should == [id]
      end
    end

  end
end
