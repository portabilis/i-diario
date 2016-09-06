class DailyNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :avaliation

  has_many :students, -> { includes(:student).order('students.name') }, class_name: 'DailyNoteStudent', dependent: :destroy

  accepts_nested_attributes_for :students

  has_enumeration_for :status, with: DailyNoteStatus,  create_helpers: true

  validates :unity, presence: true
  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :avaliation, presence: true

  validate :avaliation_date_must_be_less_than_or_equal_to_today
  before_destroy :ensure_not_has_avaliation_recovery

  scope :by_unity_classroom_discipline_and_avaliation_test_date_between,
        lambda { |unity_id, classroom_id, discipline_id, start_at, end_at| where(unity_id: unity_id,
                                                                                 classroom_id: classroom_id,
                                                                                 discipline_id: discipline_id,
                                                                                 'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                                                    .where.not(students: { id: nil })
                                                                                    .includes(:avaliation, students: :student) }

  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_test_date_between, lambda { |start_at, end_at| includes(:avaliation, students: :student).where('avaliations.test_date': start_at.to_date..end_at.to_date) }
  scope :by_avaliation_id, lambda { |avaliation_id| includes(:avaliation).where(avaliation: avaliation_id) }

  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_avaliation_test_date, -> { order('avaliations.test_date') }

  def self.by_status(status)
    incomplete_daily_note_ids = DailyNoteStudent.where('daily_note_students.note is null')
      .group(:daily_note_id)
      .pluck(:daily_note_id)

    case status
    when DailyNoteStatus::INCOMPLETE
      where(arel_table[:id].in(incomplete_daily_note_ids))
    when DailyNoteStatus::COMPLETE
      where.not(arel_table[:id].in(incomplete_daily_note_ids))
    end
  end

  def status
    if students.any? { |daily_note_student| daily_note_student.note.blank? }
      DailyNoteStatus::INCOMPLETE
    else
      DailyNoteStatus::COMPLETE
    end
  end

  private

  def self.by_teacher_id_query(teacher_id)
    joins(
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:classroom_id]
            .eq(DailyNote.arel_table[:classroom_id])
            .and(
              TeacherDisciplineClassroom.arel_table[:discipline_id]
                .eq(DailyNote.arel_table[:discipline_id])
            )
        )
        .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id)
      .and(TeacherDisciplineClassroom.arel_table[:active].eq('t')))
  end

  def ensure_not_has_avaliation_recovery
    if AvaliationRecoveryDiaryRecord.find_by_avaliation_id(avaliation)
      errors.add(:base)
      false
    end
  end

  def avaliation_date_must_be_less_than_or_equal_to_today
    return unless avaliation

    if avaliation.test_date > Time.zone.today
      errors.add(:avaliation, :must_be_less_than_or_equal_to_today)
    end
  end
end
