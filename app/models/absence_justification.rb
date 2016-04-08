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
  validates :student_id,       presence: true
  validates :unity,            presence: true
  validates :classroom_id,     presence: true
  validates :absence_date_end, presence: true,
                               uniqueness: { scope: :student_id }
  validates :absence_date,     presence: true,
                               uniqueness: { scope: :student_id }
  validates :discipline_id,    presence: true,
                               if: :frequence_type_by_discipline?
  validates :justification,    presence: true

  validate :period_absence

  scope :ordered, -> { order(arel_table[:absence_date]) }

  # search scopes
  scope :by_author, lambda { |author_id| where(author_id: author_id).uniq }
  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_student, lambda { |student| joins(:student).where('students.name ILIKE ?', "%#{student}%") }
  scope :by_absence_date, lambda { |date| where(absence_date: date) }
  scope :by_absence_date_end, lambda { |date| where(absence_date_end: date) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_date_range, lambda { |absence_date, absence_date_end| where("absence_date <= ? AND absence_date_end >= ?", absence_date_end, absence_date) }

  private

  def period_absence
    absence_justifications = AbsenceJustification.by_classroom(classroom)
      .by_student_id(student_id)
      .by_discipline_id(discipline_id)
      .by_date_range(absence_date, absence_date_end)

    absence_justifications = absence_justifications.where.not(id: id) if persisted?

    if absence_justifications.any?
      errors.add(:base, :discipline_period_absence) if frequence_type_by_discipline?
      errors.add(:absence_date)
      errors.add(:absence_date_end)
    end
  end

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def teacher
    author.try(:teacher)
  end
end
