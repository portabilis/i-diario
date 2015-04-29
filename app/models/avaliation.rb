class Avaliation < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :test_setting
  belongs_to :test_setting_test
  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(Avaliation.arel_table[:discipline_id])) }, through: :classroom

  validates :unity, :classroom, :discipline, :test_date, :class_number, :test_setting,
              :school_calendar, presence: true
  validates :test_setting_test, presence: true, if: :fix_tests?
  validates :description, presence: true, unless: :fix_tests?
  validate :unique_test_setting_test_per_step
  validate :is_school_day?

  scope :ordered, -> { order(arel_table[:test_date]) }
  scope :teacher_avaliations, lambda { |teacher_id, classroom_id, discipline_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id, discipline_id: discipline_id}) }

  def to_s
    test_setting_test || description
  end

  def description_to_teacher
    I18n.l(test_date) + ' - ' + (fix_tests? ? test_setting_test.to_s : description)
  end

  def self.data_for_select2
    where(nil).map do |avaliation|
      {
        id: avaliation.id,
        name: avaliation.description_to_teacher,
        text: avaliation.description_to_teacher
      }
    end.to_json
  end

  def fix_tests?
    return false if test_setting.nil?
    test_setting.fix_tests?
  end

  private

  def is_school_day?
    return unless school_calendar && test_date

    errors.add(:test_date, :must_be_school_day) if !school_calendar.school_day? test_date
  end

  def step
    return unless school_calendar
    school_calendar.step(test_date)
  end

  def unique_test_setting_test_per_step
    return unless step

    relation = Avaliation
    if persisted?
      relation = relation.where(Avaliation.arel_table[:id].not_eq(id))
    end
    relation = relation.where(Avaliation.arel_table[:test_setting_test_id].eq(test_setting_test_id))
    relation = relation.where(Avaliation.arel_table[:classroom_id].eq(classroom_id))
    relation = relation.where(Avaliation.arel_table[:discipline_id].eq(discipline_id))
    relation = relation.where(Avaliation.arel_table[:test_date].gteq(step.start_at))
    relation = relation.where(Avaliation.arel_table[:test_date].lteq(step.end_at))

    errors.add(:test_setting_test, :unique_per_step) if relation.any?
  end
end