class DailyNoteStudentSerializer < ActiveModel::Serializer
  attributes :id, :note

  has_one :student
end
