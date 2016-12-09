class StudentEnrollmentsListsSerializer < ActiveModel::Serializer
  attributes :id, :student_id, :status, :active

  has_one :student
end
