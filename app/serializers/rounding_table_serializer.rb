class RoundingTableSerializer < ActiveModel::Serializer
  attributes :id

  has_many :rounding_table_values
end
