class SchoolTermRecoveryDiaryRecord < ApplicationRecord
  include Audit
  include Stepable
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  before_destroy :valid_for_destruction?

  belongs_to :recovery_diary_record

  accepts_nested_attributes_for :recovery_diary_record

  delegate :classroom, :classroom_id, :discipline, :discipline_id, to: :recovery_diary_record

  scope :by_unity_id, lambda { |unity_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { unity_id: unity_id })
  }
  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { classroom_id: classroom_id })
  }
  scope :by_discipline_id, lambda { |discipline_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { discipline_id: discipline_id })
  }
  scope :by_recorded_at, lambda { |recorded_at| where(recorded_at: recorded_at) }
  scope :by_not_poster, ->(poster_sent) { where("school_term_recovery_diary_records.updated_at > ?", poster_sent) }
  scope :ordered, -> { order(arel_table[:recorded_at].desc) }

  before_validation :set_recorded_at, on: [:create, :update]

  validates :recovery_diary_record, presence: true
  validate :recovery_type_must_allow_recovery_for_step
  validate :recovery_type_must_allow_recovery_for_classroom
  validate :uniqueness_of_school_term_recovery_diary_record

  def test_date
    recorded_at
  end

  def ignore_date_validates
    !(new_record? || recorded_at != recorded_at_was)
  end

  private

  def self.by_teacher_id_query(teacher_id)
    joins(
      :recovery_diary_record,
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:classroom_id]
            .eq(RecoveryDiaryRecord.arel_table[:classroom_id])
            .and(
              TeacherDisciplineClassroom.arel_table[:discipline_id]
                .eq(RecoveryDiaryRecord.arel_table[:discipline_id])
            )
        )
        .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id)
      .and(TeacherDisciplineClassroom.arel_table[:active].eq('t')))
  end

  def set_recorded_at
    return if recovery_diary_record.blank?

    self.recovery_diary_record.recorded_at = recorded_at
  end

  def uniqueness_of_school_term_recovery_diary_record
    return if recovery_diary_record.blank? || step.blank?

    relation = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_id)
                                            .by_discipline_id(discipline_id)
                                            .by_step_id(classroom, step_id)

    relation = relation.where.not(id: id) if persisted?

    if relation.any?
      errors.add(:step_id, :uniqueness_of_school_term_recovery_diary_record)
    end
  end

  def classroom_grades_with_recovery_rule
    return @classroom_grade if @classroom_grade.present?

    @classroom_grade = []

    classroom_grades&.each { |classroom_grade| @classroom_grade << classroom_grade unless classroom_grade.exam_rule.recovery_type.eql?(0) }

    if @classroom_grade.empty?
      classroom_grades
    else
      @classroom_grade
    end
  end

  def classroom_grades
    classroom.classrooms_grades.includes(:exam_rule)
  end

  def recovery_type_must_allow_recovery_for_classroom
    return if recovery_diary_record.blank? || classroom.blank?
    if classroom_grades_with_recovery_rule.first.exam_rule.recovery_type == RecoveryTypes::DONT_USE
      errors.add(:recovery_diary_record, :recovery_type_must_allow_recovery_for_classroom)
      recovery_diary_record.errors.add(:classroom, :recovery_type_must_allow_recovery_for_classroom)
    end
  end

  def recovery_type_must_allow_recovery_for_step
    return if recovery_diary_record.blank? || classroom.blank? || step.blank?
    return if classroom_grades_with_recovery_rule.first.exam_rule.recovery_type != RecoveryTypes::SPECIFIC

    if classroom_grades_with_recovery_rule.first.exam_rule.recovery_exam_rules.none? { |r| r.steps.include?(step.to_number) }
      errors.add(:step_id, :recovery_type_must_allow_recovery_for_step)
    end
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      recovery_diary_record.validation_type = :destroy
      recovery_diary_record.valid?
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')
      if recovery_diary_record.errors[:recorded_at].include?(forbidden_error)
        errors.add(:base, forbidden_error)
        false
      else
        true
      end
    end
  end
end
