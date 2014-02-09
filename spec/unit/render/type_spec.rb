require "render/type"

module Render
  describe Type do
    before(:each) do
      @original_types = Type.instances.dup
    end

    after(:each) do
      Type.instances = @original_types
    end

    describe ".parse" do
      it "returns constant for string" do
        Type.parse("integer").should == Integer
      end

      it "returns argument when not a string" do
        class ::Foo; end
        Type.parse(Foo).should == Foo
        Object.__send__(:remove_const, :Foo)
      end

      it "raises meaningful error for unmatched types" do
        expect {
          Type.parse!("NotAClass")
        }.to raise_error(Render::Errors::InvalidType)
      end

      describe "non-standard formats" do
        it "maps regardless of capitalization" do
          string_representations = %w(uuid UUID)
          string_representations.each do |name|
            Type.parse(name).should == UUID
          end
        end

        it "returns UUID for uuid" do
          Type.parse("uUId").should == UUID
        end

        it "returns Boolean for boolean" do
          Type.parse("boolean").should == Render::Type::Boolean
        end

        it "returns Float for number" do
          Type.parse("FloAt").should == Float
        end

        it "returns Time for date-time" do
          Type.parse("date-time").should == Time
        end
      end
    end

    describe ".find" do
      it "returns Render's custom types" do
        Type.find(:boolean).should == Render::Type::Boolean
      end

      it "returns falsie when no type is found" do
        Type.find(:foo).should_not be
      end

      describe "user type" do
        before(:each) do
          @original_types = Type.instances.dup
          module ::Foo; module Boolean; end; end
          Type.add!(:boolean, Foo::Boolean)
        end

        after(:each) do
          Type.instances = @original_types
          Object.__send__(:remove_const, :Foo)
        end

        it "is returned instead of Render's" do
          Type.find(:boolean).should == Foo::Boolean
        end
      end
    end
  end
end
