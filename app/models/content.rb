class Content < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit
  include Filterable

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar

  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(Content.arel_table[:discipline_id])) }, through: :classroom

  validates :unity, :classroom, :school_calendar,  :content_date, :theme, presence: true
  validates :classes, presence: true, if: :classroom_required?
  validate :is_school_day?


  scope :by_teacher_id, (lambda do |teacher_id|
      joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
          .on(
            TeacherDisciplineClassroom.arel_table[:classroom_id].eq(arel_table[:classroom_id])
              .and(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(arel_table[:discipline_id]).or(arel_table[:discipline_id].eq(nil)))
          )
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id))
      .uniq
    end)
  scope :by_unity_id, lambda { |unity_id| where unity_id: unity_id }
  scope :by_classroom_id, lambda { |classroom_id| where classroom_id: classroom_id }
  scope :by_content_date, lambda { |content_date| where(content_date: content_date) }

  scope :ordered, -> { order(arel_table[:content_date]) }

  def to_s
    description
  end

  def classes=(classes)
    write_attribute(:classes, classes ? classes.split(',').sort.map(&:to_i) : classes)
  end

  private

  def classroom_required?
    if (ExamRule.by_id(classroom == nil ? 0 : classroom.exam_rule_id ).by_frequency_type '1') == []
      return true
    end
  end

  def is_school_day?
    return unless school_calendar && content_date

    errors.add(:content_date, :must_be_school_day) if !school_calendar.school_day? content_date
  end
end
