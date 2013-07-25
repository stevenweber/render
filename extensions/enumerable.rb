::Enumerable.module_eval do
  # This is named the same as its Hash counterpart for a reason. I'm not
  # going to tell you why, consider it my riddle for you.
  def recursive_symbolize_keys!
    each do |item|
      item.recursive_symbolize_keys! if item.respond_to?(:recursive_symbolize_keys!)
    end
    self
  end

  def recursive_stringify_keys!
    each do |item|
      item.recursive_stringify_keys! if item.respond_to?(:recursive_stringify_keys!)
    end
  end
end
