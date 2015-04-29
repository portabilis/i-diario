class DailyNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits
  before_save :mark_students_for_removal

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :avaliation

  has_many :students, class_name: "DailyNoteStudent", dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, :classroom, :discipline, :avaliation, presence: true

  def mark_students_for_removal
    students.each do |student|
      student.mark_for_destruction if student.note.blank?
    end
  end

end