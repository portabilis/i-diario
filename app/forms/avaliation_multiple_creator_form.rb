class AvaliationMultipleCreatorForm
  include ActiveModel::Model
  include I18n::Alchemy

  attr_accessor :test_setting_id, :unity_id, :discipline_id, :test_setting_test_id,
                :test_date, :classes, :description, :weight, :observations, :classrooms,
                :school_calendar_id

  validates :unity,             presence: true
  validates :discipline,        presence: true
  validates :test_date,         presence: true, school_calendar_day: true
  validates :classes,           presence: true
  validates :school_calendar,   presence: true
  validates :test_setting,      presence: true
  validates :test_setting_test, presence: true, if: :fix_tests?
  validates :description,       presence: true, if: -> { !fix_tests? || allow_break_up? }
  validates :weight,            presence: true, if: :allow_break_up?
  validate :is_school_term_day?

  def test_setting
    return if test_setting_id.blank?
    @test_setting ||= TestSetting.find(test_setting_id)
  end

  def unity
    return if unity_id.blank?
    @unity ||= Unity.find(unity_id)
  end

  def discipline
    return if discipline_id.blank?
    @discipline ||= Discipline.find(discipline_id)
  end

  def test_setting_test
    return if test_setting_test_id.blank?
    @test_setting_test ||= TestSettingTest.find(test_setting_test_id)
  end

  def classes=(classes)
    write_attribute(:classes, classes ? classes.split(',').sort.map(&:to_i) : classes)
  end

  protected

  def allow_break_up?
    test_setting_test && test_setting_test.allow_break_up
  end

  def fix_tests?
    return false if test_setting.nil?
    test_setting.fix_tests?
  end

  def is_school_term_day?
    return if test_setting.nil? || test_setting.exam_setting_type == ExamSettingTypes::GENERAL

    errors.add(:test_date, :must_be_school_term_day) if !school_calendar.school_term_day?(test_setting.school_term, test_date)
  end
end
