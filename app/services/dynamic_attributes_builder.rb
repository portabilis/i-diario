module DynamicAttributesBuilder
  def self.build(model)
    "DynamicAttributesBuilder::#{model}".constantize.new(model)
  end
end
