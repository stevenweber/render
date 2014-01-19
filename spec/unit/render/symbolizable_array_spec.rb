module Render
  describe SymbolizableArray do
    describe "#initialize" do
      it "recursively casts Hashes as DottableHashes" do
        result = SymbolizableArray.new([{ "a" => :b }])
        result.first.should be_a(DottableHash)
      end

      it "recursively casts Arrays as SymbolizableArrays" do
        result = SymbolizableArray.new([[1]])
        result.first.should be_a(SymbolizableArray)
      end

    end
  end
end
