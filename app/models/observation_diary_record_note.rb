class ObservationDiaryRecordNote < ActiveRecord::Base
  include Audit

  acts_as_copy_target
  audited associated_with: [:observation_diary_record],
          except: [:observation_diary_record_id]
  has_associated_audits

  belongs_to :observation_diary_record
  has_many(
    :note_students,
    class_name: 'ObservationDiaryRecordNoteStudent',
    dependent: :destroy
  )
  has_many :students, through: :note_students

  validates :observation_diary_record, presence: true
  validates :description, presence: true

  def student_ids
    students.collect(&:id).join(',')
  end
end
