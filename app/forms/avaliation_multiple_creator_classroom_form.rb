class AvaliationMultipleCreatorClassroomForm
  include ActiveModel::Model
  include I18n::Alchemy
  localize :test_date, :using => :date


  attr_accessor :classroom_id, :test_date, :classes, :avaliation_multiple_creator_form

  validates :classroom_id,      presence: true
  validates :test_date,         presence: true, school_calendar_day: true
  validates :classes,           presence: true
  validate :is_school_term_day?

  def classroom
    @classroom ||= Classroom.find_by(id: classroom_id)
  end

  def school_calendar
    @school_calendar ||= SchoolCalendar.find_by(id: school_calendar_id)
  end

  protected

  def is_school_term_day?
    return if test_setting.nil? || test_setting.exam_setting_type == ExamSettingTypes::GENERAL

    errors.add(:test_date, :must_be_school_term_day) if !school_calendar.school_term_day?(test_setting.school_term_type_step, test_date)
  end

  def test_setting
    avaliation_multiple_creator_form.test_setting
  end

  def school_calendar
    avaliation_multiple_creator_form.school_calendar
  end
end
