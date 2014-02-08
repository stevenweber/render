require "render/types"

module Render
  describe Types do
    describe ".find" do
      it "returns Render's custom types" do
        Types.find(:boolean).should == Render::Types::Boolean
      end

      it "returns falsie when no type is found" do
        Types.find(:foo).should_not be
      end

      describe "user type" do
        before(:each) do
          @original_types = Types.types.dup
          module ::Foo; module Boolean; end; end
          Types.add!(:boolean, Foo::Boolean)
        end

        after(:each) do
          Types.types = @original_types
          Object.__send__(:remove_const, :Foo)
        end

        it "is returned instead of Render's" do
          Types.find(:boolean).should == Foo::Boolean
        end
      end
    end
  end
end
