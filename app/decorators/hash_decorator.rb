class HashDecorator < SimpleDelegator
  def initialize(hash)
    super(JSON.parse(hash.to_json, object_class: OpenStruct))
  end

  def key_exist?(key)
    self[key].present?
  end
end
