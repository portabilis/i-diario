class DescriptiveExam < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  # acts_as_paranoid

  audited
  has_associated_audits
  before_save :mark_students_for_removal

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step, -> { unscope(where: :active) }
  belongs_to :school_calendar_classroom_step, -> { unscope(where: :active) }

  delegate :unity, to: :classroom, allow_nil: true

  has_many :students, class_name: 'DescriptiveExamStudent', dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, presence: true
  validates :classroom_id, presence: true
  validates :opinion_type, presence: true
  validates :discipline_id, presence: true, if: :should_validate_presence_of_discipline
  validates :school_calendar_step_id, presence: true, if: :should_validate_presence_of_school_calendar_step
  validates :school_calendar_classroom_step_id, presence: true, if: :should_validate_presence_of_classroom_school_calendar_step

  validate :check_posting_date

  def mark_students_for_removal
    students.each do |student|
      student.mark_for_destruction if student.value.blank?
    end
  end

  def step
    @step ||= school_calendar_classroom_step || school_calendar_step
  end

  private

  def should_validate_presence_of_discipline
    return unless opinion_type

    [OpinionTypes::BY_STEP_AND_DISCIPLINE, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include? opinion_type
  end

  def should_validate_presence_of_school_calendar_step
    return unless opinion_type

    by_step = [OpinionTypes::BY_STEP_AND_DISCIPLINE, OpinionTypes::BY_STEP].include? opinion_type
    by_step && !school_calendar_classroom_step_id
  end

  def should_validate_presence_of_classroom_school_calendar_step
    return unless opinion_type

    by_step = [OpinionTypes::BY_STEP_AND_DISCIPLINE, OpinionTypes::BY_STEP].include? opinion_type
    by_step && !school_calendar_step_id
  end

  def check_posting_date
    return unless classroom && step

    return true if PostingDateChecker.new(classroom, step.start_at).check
    errors.add(:school_calendar_classroom_step_id, I18n.t('errors.messages.not_allowed_to_post_in_date'))
    errors.add(:school_calendar_step_id, I18n.t('errors.messages.not_allowed_to_post_in_date'))
  end
end
