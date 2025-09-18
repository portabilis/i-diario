class DailyPhysicalFrequency < ApplicationRecord
  belongs_to :student_enrollment
  belongs_to :unity

  validates :frequency_date, presence: true, school_calendar_day: true
  validates :student_enrollment_id, presence: true
  validates :present, inclusion: { in: [true, false] }

  validate :frequency_date_must_be_in_a_valid_step
  validate :frequency_date_must_be_less_than_or_equal_to_today

  scope :by_unity_api_code, ->(api_code) {
    return all if api_code.blank?
    joins(:unity).where(unities: { api_code: api_code })
  }

  scope :by_student_enrollment_api_code, ->(api_code) {
    return all if api_code.blank?
    joins(:student_enrollment).where(student_enrollments: { api_code: api_code })
  }

  scope :by_frequency_date, ->(date) {
    return all if date.blank?
    where(frequency_date: date)
  }

  def classroom
    return @classroom if defined?(@classroom)
    return nil if student_enrollment.nil? || frequency_date.nil?

    active_enrollment_classroom = student_enrollment.student_enrollment_classrooms
                                                    .by_date(self.frequency_date)
                                                    .first

    @classroom = active_enrollment_classroom ? Classroom.find_by(api_code: active_enrollment_classroom.classroom_code) : nil
  end

  def school_calendar
    classroom = self.classroom
    return nil unless classroom

    StepsFetcher.new(classroom).school_calendar
  end

  private

  def frequency_date_must_be_in_a_valid_step
    classroom = self.classroom

    if classroom.nil?
      errors.add(:base, :no_active_classroom_enrollment, student_name: student_enrollment.student.name, student_enrollment_api_code: student_enrollment.api_code)
      return
    end

    step = StepsFetcher.new(classroom).step_by_date(frequency_date)
  end

  def frequency_date_must_be_less_than_or_equal_to_today
    return unless frequency_date

    if frequency_date > Time.zone.today
      errors.add(:frequency_date, :must_be_less_than_or_equal_to_today)
    end
  end
end

