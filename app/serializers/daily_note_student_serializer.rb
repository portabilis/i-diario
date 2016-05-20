class DailyNoteStudentSerializer < ActiveModel::Serializer
  attributes :id, :note, :daily_note_id

  has_one :student
  has_one :avaliation
end
