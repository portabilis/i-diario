class StudentSerializer < ActiveModel::Serializer
  attributes :id, :name, :exempted_from_discipline

  def name
    object.to_s
  end
end
