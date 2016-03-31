class AbsenceJustification < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable

  belongs_to :author, class_name: 'User'
  belongs_to :student
  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline

  validates :author,           presence: true
  validates :student,          presence: true
  validates :unity,            presence: true
  validates :classroom_id,     presence: true
  validates :absence_date_end, presence: true,
                               uniqueness: { scope: :student_id }
  validates :absence_date,     presence: true,
                               uniqueness: { scope: :student_id }
  validates :discipline,       presence: true,
                               uniqueness: { scope: :student_id }
  validates :justification,    presence: true

  scope :ordered, -> { order(arel_table[:absence_date]) }

  # search scopes
  scope :by_author, lambda { |author_id| where(author_id: author_id).uniq }
  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_student, lambda { |student| joins(:student).where('students.name ILIKE ?', "%#{student}%") }
  scope :by_absence_date, lambda { |date| where(absence_date: date) }
  scope :by_absence_date_end, lambda { |date| where(absence_date_end: date) }
end
