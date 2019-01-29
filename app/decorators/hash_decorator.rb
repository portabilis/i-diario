class HashDecorator < SimpleDelegator
  def initialize(hash)
    super(JSON.parse(hash.to_json, object_class: OpenStruct))
  end

  def defined?(key)
    self[key].present?
  end
end
