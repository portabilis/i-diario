class AvaliationRecoveryDiaryRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited
  has_associated_audits

  before_destroy :valid_for_destruction?

  belongs_to :recovery_diary_record
  belongs_to :avaliation
  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline

  accepts_nested_attributes_for :recovery_diary_record

  delegate :classroom, :classroom_id, :discipline, :discipline_id, to: :recovery_diary_record

  scope :by_unity_id, lambda { |unity_id| joins(:recovery_diary_record).where(recovery_diary_records: { unity_id: unity_id }) }
  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:recovery_diary_record).where(recovery_diary_records: { classroom_id: classroom_id }) }
  scope :by_discipline_id, lambda { |discipline_id| joins(:recovery_diary_record).where(recovery_diary_records: { discipline_id: discipline_id }) }
  scope :by_school_calendar_id, lambda { |school_calendar_id| where(school_calendar_id: school_calendar_id) }
  scope :by_recorded_at, lambda { |recorded_at| joins(:recovery_diary_record).where(recovery_diary_records: { recorded_at: recorded_at }) }
  scope :by_avaliation_id, lambda { |avaliation_id| where(avaliation_id: avaliation_id) }
  scope :by_avaliation_description, lambda { |avaliation_description|
    joins(:avaliation).where('unaccent(avaliations.description) ILIKE unaccent(?)', "%#{avaliation_description}%" )
  }
  scope :by_test_date_between, lambda { |start_at, end_at|
    joins(:avaliation).where(avaliations: { test_date: start_at.to_date..end_at.to_date })
  }
  scope :ordered, -> { joins(:recovery_diary_record).order(RecoveryDiaryRecord.arel_table[:recorded_at].desc) }

  validates :avaliation, :recovery_diary_record, presence: true

  validate :uniqueness_of_avaliation_recovery_diary_record
  validate :recovery_date_should_be_greater_or_equal_avaliation_date, if: :dates_are_set?

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

  def uniqueness_of_avaliation_recovery_diary_record
    return unless recovery_diary_record

    relation = AvaliationRecoveryDiaryRecord
      .by_classroom_id(recovery_diary_record.classroom_id)
      .by_discipline_id(recovery_diary_record.discipline_id)
      .by_avaliation_id(avaliation_id)
    relation = relation.where.not(id: id) if persisted?

    errors.add(:avaliation, :uniqueness_of_avaliation_recovery_diary_record) if relation.any?
  end

  def recovery_date_should_be_greater_or_equal_avaliation_date
    if !(recovery_diary_record.recorded_at >= avaliation.test_date)
      errors.add(:recovery_diary_record, :recovery_date_should_be_greater_or_equal_avaliation_date)
      recovery_diary_record.errors.add(:recorded_at, :recovery_date_should_be_greater_or_equal_avaliation_date)
    end
  end

  def dates_are_set?
    return if recovery_diary_record.blank? || avaliation.blank?

    recovery_diary_record.recorded_at.present? && avaliation.test_date.present?
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
