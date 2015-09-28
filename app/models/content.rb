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


  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :by_teacher_classroom_and_discipline, lambda { |teacher_id, classroom_id, discipline_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id, discipline_id: discipline_id}) }
  scope :ordered, -> { order(arel_table[:content_date]) }
  scope :by_classes, lambda { |classes| where("classes && ARRAY#{classes}::INTEGER[]") }
  scope :by_unity, lambda { |unity| where unity_id: unity }
  scope :by_classroom, lambda { |classroom| where classroom_id: classroom }
  scope :by_date, lambda { |date| where(content_date: date) }

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
