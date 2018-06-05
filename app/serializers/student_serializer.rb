class StudentSerializer < ActiveModel::Serializer
  attributes :id, :name, :exempted_from_discipline
end
