class ComplementaryExamSettingSerializer < ActiveModel::Serializer
  attributes :id, :description, :number_of_decimal_places, :affected_score
end
