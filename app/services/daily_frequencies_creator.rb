class DailyFrequenciesCreator
  attr_reader :daily_frequencies

  def initialize(params, class_numbers = nil)
    @params = params
    @class_numbers = class_numbers
  end

  def self.find_or_create!(params, class_numbers)
    new(params, class_numbers).find_or_create!
  end

  def find_or_create!
    ActiveRecord::Base.transaction do
      find_or_create_daily_frequencies
      find_or_create_daily_frequency_students
    end
    true
  end

  private

  def find_or_create_daily_frequencies
    @daily_frequencies = []
    if @class_numbers.present?
      @class_numbers.each do |class_number|
        @daily_frequencies << DailyFrequency.find_or_create_by(@params.merge({class_number: class_number}))
      end
    else
      @daily_frequencies << DailyFrequency.find_or_create_by(@params)
    end
  end

  def find_or_create_daily_frequency_students
    fetch_student_enrollments

    @student_enrollments.each do |student_enrollment|
      student = student_enrollment.student
      dependence = student_has_dependence?(student_enrollment.id, first_daily_frequency.discipline_id)
      @daily_frequencies.each do |daily_frequency|
        (daily_frequency.students.where(student_id: student.id).first ||
         daily_frequency.students.create(student_id: student.id,
                                         dependence: dependence,
                                         present: true,
                                         active: true))
      end
    end
  end

  def fetch_student_enrollments
    frequency_date = @params[:frequency_date] || Time.zone.today
    @student_enrollments = StudentEnrollment
      .includes(:student)
      .by_classroom(first_daily_frequency.classroom)
      .by_discipline(first_daily_frequency.discipline)
      .by_date(frequency_date)
      .active
      .ordered
  end

  def first_daily_frequency
    @first_daily_frequency ||= @daily_frequencies[0]
  end

  def student_has_dependence?(student_enrollment_id, discipline_id)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment_id)
      .by_discipline(discipline_id)
      .any?
  end
end
