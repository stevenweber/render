require "render/graph"

module Render
  describe Graph do
    describe "relationships" do
      #
    end

    describe "#render" do
      before(:each) do
        Render.stub({ live: false })
        @hash_definition = {
          title: :book,
          type: Object,
          properties: {
            title: { type: String }
          }
        }
        @array_definition = {
          title: :books,
          type: Array,
          items: {
            ids: { type: UUID }
          }
        }
      end

      it "uses explicit data for hashes" do
        graph = Render::Graph.new(@hash_definition)
        green_eggs_and_ham = "Green Eggs and Ham"
        data = graph.render({ title: green_eggs_and_ham })
        data.book.title.should == green_eggs_and_ham
      end

      it "uses explicit nil data for hashes" do
        graph = Render::Graph.new(@hash_definition)
        data = graph.render({ title: nil })
        data.book.title.should == nil
      end

      it "uses explicit data for arrays" do
        pending "this passes for the wrong reason"
        graph = Render::Graph.new(@array_definition)
        data = graph.render([])
        data.books.should == []
      end

      it "uses explicit data for nested data"
    end
  end
end
