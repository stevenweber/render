class ::Hash
  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end

  def stringify_keys
    dup.stringify_keys!
  end

  def recursive_stringify_keys!
    stringify_keys!
    values.each do |value|
      value.recursive_stringify_keys! if value.respond_to?(:recursive_stringify_keys!)
    end
    self
  end

  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end

  def recursive_symbolize_keys!
    symbolize_keys!
    values.each do |value|
      value.recursive_symbolize_keys! if value.respond_to?(:recursive_symbolize_keys!)
    end
    self
  end

  def symbolize_keys
    dup.symbolize_keys!
  end

  def hardcode(other_hash)
    dup.hardcode!(other_hash)
  end

  def hardcode!(other_hash)
    other_hash.each_pair do |k,v|
      tv = self[k]
      self[k] = tv.respond_to?(:hardcode) && v.respond_to?(:hardcode) ? tv.hardcode(v) : v
    end
    self
  end

end
