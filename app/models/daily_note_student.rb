class DailyNoteStudent < ApplicationRecord
  include Discardable

  acts_as_copy_target

  audited associated_with: [:daily_note, :transfer_note], except: [:daily_note_id, :transfer_note_id, :active]

  attr_accessor :exempted, :dependence, :exempted_from_discipline, :in_active_search

  before_save :nullify_notes_for_inactive_students

  belongs_to :daily_note
  belongs_to :student
  belongs_to :transfer_note

  delegate :avaliation, to: :daily_note
  delegate :unity, to: :daily_note
  delegate :classroom, to: :daily_note
  delegate :discipline_id, to: :daily_note

  validates :student,    presence: true
  validates :daily_note, presence: true
  validates :note, numericality: { greater_than_or_equal_to: :minimum_score, less_than_or_equal_to: lambda { |daily_note_student| daily_note_student.maximum_score } }, allow_blank: true

  default_scope -> { kept }

  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_discipline_id, lambda { |discipline_id| joins(:daily_note).merge(DailyNote.by_discipline_id(discipline_id)) }
  scope :exclude_discipline_ids, lambda { |discipline_ids| joins(:daily_note).merge((DailyNote.exclude_discipline_ids(discipline_ids))) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:daily_note).merge(DailyNote.by_classroom_id(classroom_id)) }
  scope :not_including_classroom_id, lambda { |classroom_id| joins(:daily_note).merge(DailyNote.not_including_classroom_id(classroom_id)) }
  scope :by_test_date_between, lambda { |start_at, end_at| by_test_date_between(start_at, end_at) }
  scope :by_avaliation, lambda { |avaliation| joins(:daily_note).merge(DailyNote.by_avaliation_id(avaliation)) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { joins(:student, daily_note: :avaliation).order(Avaliation.arel_table[:test_date], Student.arel_table[:name]) }
  scope :order_by_discipline_and_date, -> { joins(daily_note: [avaliation: :discipline]).order('disciplines.description, avaliations.test_date') }
  scope :by_not_poster, ->(poster_sent) { where("daily_note_students.updated_at > ?", poster_sent) }

  def dependence?
    self.dependence
  end

  def maximum_score
    MaximumScoreFetcher.new(avaliation).maximum_score
  end

  def recovered_note
    recovery_note.to_f > note.to_f ? recovery_note : note.to_f
  end

  def minimum_score
    daily_note.avaliation.test_setting.minimum_score
  end

  def recovery_note
    if has_recovery?
      recovery_diary_record_id = daily_note.avaliation.recovery_diary_record.id
      RecoveryDiaryRecordStudent.
        find_by(recovery_diary_record_id: recovery_diary_record_id, student_id: student.id).try(:score)
    else
      0.0
    end
  end

  def has_recovery?
    daily_note.avaliation.recovery_diary_record.present?
  end

  def exempted?
    if AvaliationExemption.find_by_student_id(student_id).present?
      AvaliationExemption.by_student(student_id)
                         .by_avaliation(daily_note.try(:avaliation_id))
                         .any?
    end
  end

  private

  def self.by_test_date_between(start_at, end_at)
    joins(
      :daily_note,
      arel_table.join(Avaliation.arel_table, Arel::Nodes::OuterJoin)
        .on(
          Avaliation.arel_table[:id]
            .eq(DailyNote.arel_table[:avaliation_id])
        )
        .join_sources
    )
    .where(avaliations: { test_date: start_at.to_date..end_at.to_date })
  end

  def nullify_notes_for_inactive_students
    self.note = nil if !self.active
  end
end
