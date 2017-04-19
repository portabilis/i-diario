class AvaliationSerializer < ActiveModel::Serializer
  attributes :id, :description_to_teacher, :test_date, :description, :classroom,
             :discipline, :test_date_humanized, :test_date_today
end
