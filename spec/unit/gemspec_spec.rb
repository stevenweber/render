describe :gemspec do
  it "is valid" do
    spec = Gem::Specification::load("render.gemspec")
    expect {
      spec.validate
    }.not_to raise_error
  end
end
