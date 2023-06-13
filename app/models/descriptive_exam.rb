class DescriptiveExam < ApplicationRecord
  include Audit
  include Stepable
  include TeacherRelationable

  teacher_relation_columns only: [:classroom, :discipline]

  acts_as_copy_target

  audited
  has_associated_audits

  before_save :mark_students_for_removal

  belongs_to :classroom
  belongs_to :discipline

  has_many :students, class_name: 'DescriptiveExamStudent', dependent: :destroy

  accepts_nested_attributes_for :students

  delegate :unity, to: :classroom, allow_nil: true

  scope :by_teacher_id,
        lambda { |teacher_id|
          joins(discipline: :teacher_discipline_classrooms)
            .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
            .distinct
        }

  scope :by_unity_id, ->(unity_id) { joins(:classroom).where(classrooms: { unity_id: unity_id }) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_discipline_id, ->(discipline_id) { where(discipline_id: discipline_id) }
  scope :by_step_number, ->(step_number) { where(step_number: step_number) }

  validates :unity, presence: true
  validates :opinion_type, presence: true
  validates :discipline_id, presence: true, if: :should_validate_presence_of_discipline
  validate :check_posting_date

  def mark_students_for_removal
    students.each do |student|
      student.mark_for_destruction if student.value.blank?
    end
  end

  def ignore_step
    opinion_type_by_year?
  end

  private

  def should_validate_presence_of_discipline
    return if opinion_type.blank?

    [OpinionTypes::BY_STEP_AND_DISCIPLINE, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(opinion_type)
  end

  def check_posting_date
    return if classroom.blank? || step.blank?
    return if [OpinionTypes::BY_YEAR_AND_DISCIPLINE, OpinionTypes::BY_YEAR].include?(opinion_type)

    return true if PostingDateChecker.new(classroom, step.start_date_for_posting).check

    errors.add(:step_id, I18n.t('errors.messages.not_allowed_to_post_in_date'))
  end

  def opinion_type_by_year?
    [OpinionTypes::BY_YEAR, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(opinion_type)
  end

  def ignore_date_validates
    true
  end
end
