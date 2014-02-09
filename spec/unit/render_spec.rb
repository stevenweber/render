require "render"

describe Render do
  # Just give me this one existential thought to commemerate Prague.
  it "exists" do
    Render.should be_true
  end

  describe "configuration" do
    describe ".live" do
      before(:each) do
        @original_live = Render.live
      end

      after(:each) do
        Render.live = @original_live
      end

      it "defaults to true" do
        Render.live.should == true
      end

      it "can be set to faux-request mode" do
        Render.live = false
        Render.live.should == false
      end
    end

    describe "logger" do
      it "exits" do
        Render.logger.should be
      end
    end

    describe ".parse_type" do
      it "returns constant for string" do
        Render.parse_type("integer").should == Integer
      end

      it "returns argument when not a string" do
        class Foo; end
        Render.parse_type(Foo).should == Foo
        Object.__send__(:remove_const, :Foo)
      end

      it "raises meaningful error for unmatched types" do
        expect {
          Render.parse_type("NotAClass")
        }.to raise_error(Render::Errors::InvalidType)
      end

      describe "non-standard formats" do
        it "maps regardless of capitalization" do
          string_representations = %w(uuid UUID)
          string_representations.each do |name|
            Render.parse_type(name).should == UUID
          end
        end

        it "returns UUID for uuid" do
          Render.parse_type("uUId").should == UUID
        end

        it "returns Boolean for boolean" do
          Render.parse_type("boolean").should == Render::Types::Boolean
        end

        it "returns Float for number" do
          Render.parse_type("FloAt").should == Float
        end

        it "returns Time for date-time" do
          Render.parse_type("date-time").should == Time
        end
      end
    end
  end
end
