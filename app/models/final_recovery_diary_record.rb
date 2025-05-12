class FinalRecoveryDiaryRecord < ApplicationRecord
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  before_destroy :valid_for_destruction?

  belongs_to :recovery_diary_record
  belongs_to :school_calendar

  accepts_nested_attributes_for :recovery_diary_record

  delegate :classroom, :classroom_id, :discipline, :discipline_id, to: :recovery_diary_record

  scope :by_unity_id, lambda { |unity_id| joins(:recovery_diary_record).where(recovery_diary_records: { unity_id: unity_id }) }
  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:recovery_diary_record).where(recovery_diary_records: { classroom_id: classroom_id }) }
  scope :by_discipline_id, lambda { |discipline_id| joins(:recovery_diary_record).where(recovery_diary_records: { discipline_id: discipline_id }) }
  scope :by_school_calendar_id, lambda { |school_calendar_id| where(school_calendar_id: school_calendar_id) }
  scope :by_recorded_at, lambda { |recorded_at| joins(:recovery_diary_record).where(recovery_diary_records: { recorded_at: recorded_at }) }
  scope :ordered, -> { joins(:recovery_diary_record).order(RecoveryDiaryRecord.arel_table[:recorded_at].desc) }

  validates :recovery_diary_record, presence: true
  validates :school_calendar, presence: true
  validates :year, presence: true

  validate :uniqueness_of_final_recovery_diary_record
  validate :recorded_at_must_be_in_last_school_calendar_step
  validate :uniqueness_of_recorded_at

  def year
    school_calendar.try(:year)
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

  def uniqueness_of_final_recovery_diary_record
    return unless recovery_diary_record

    relation = FinalRecoveryDiaryRecord.by_classroom_id(recovery_diary_record.classroom_id)
      .by_discipline_id(recovery_diary_record.discipline_id)
      .by_school_calendar_id(school_calendar_id)
    relation = relation.where.not(id: id) if persisted?

    errors.add(:year, :uniqueness_of_final_recovery_diary_record) if relation.any?
  end

  def recorded_at_must_be_in_last_school_calendar_step
    return unless recovery_diary_record && school_calendar

    steps = school_calendar.classrooms.by_classroom_id(recovery_diary_record.classroom_id).first.try(&:classroom_steps)
    steps ||= school_calendar.steps

    unless steps.to_a.last.school_calendar_day_allows_entry?(recovery_diary_record.recorded_at)
      errors.add(:recovery_diary_record, :recorded_at_must_be_in_last_school_calendar_step)
      recovery_diary_record.errors.add(:recorded_at, :recorded_at_must_be_in_last_school_calendar_step)
    end
  end

  def uniqueness_of_recorded_at
    return unless recovery_diary_record

    relation = RecoveryDiaryRecord.find_by(unity_id: recovery_diary_record.unity_id, classroom_id: recovery_diary_record.classroom_id, discipline_id: recovery_diary_record.discipline_id)

    recovery_diary_record.errors.add(:recorded_at, :uniqueness_of_recorded_at) if relation
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
