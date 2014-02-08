require "render/graph"

module Render
  describe Graph do
    describe "relationships" do
      #
    end

    context "not live" do
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
              type: UUID
            }
          }
        end

        it "generates random number of array elements" do
          graph = Graph.new(@array_definition)
          generated_book_sizes = 5.times.collect { graph.render!.books.size }
          generated_book_sizes.compact.size.should > 1
        end

        context "explicit data" do
          it "uses explicit data for hashes" do
            graph = Render::Graph.new(@hash_definition)
            green_eggs_and_ham = "Green Eggs and Ham"
            data = graph.render!({ title: green_eggs_and_ham })
            data.book.title.should == green_eggs_and_ham
          end

          it "uses explicit nil data for hashes" do
            graph = Render::Graph.new(@hash_definition)
            data = graph.render!({ title: nil })
            data.book.title.should == nil
          end

          it "uses explicit data for arrays" do
            graph = Render::Graph.new(@array_definition)
            id = UUID.generate
            graph.render!([id]).books.should == [id]
            graph.render!([]).books.should == []
          end

          it "uses explicit data for nested data" do
            @array_definition[:items] = @hash_definition
            nested_graph = Graph.new(@array_definition)
            tell_tale_heart = "The Tell-Tale Heart"
            data = nested_graph.render!([{ title: tell_tale_heart }])
            data.books.size.should == 1
            data.books.first.title.should == tell_tale_heart
          end

        end
      end
    end
  end
end
