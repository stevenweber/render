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

  end
end
