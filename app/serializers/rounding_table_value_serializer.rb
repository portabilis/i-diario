class RoundingTableValueSerializer < ActiveModel::Serializer
  attributes :id, :value, :to_s

  def to_s
    object.to_s
  end
end
