class DailyFrequenciesCreator
  attr_reader :daily_frequencies

  def initialize(params, class_numbers = nil)
    @params = params
    @class_numbers = class_numbers
    @params[:frequency_date] ||= Time.zone.today
  end

  def self.find_or_create!(params, class_numbers)
    new(params, class_numbers).find_or_create!
  end

  def find_or_create!
    find_or_create_daily_frequencies
    find_or_create_daily_frequency_students
    true
  end

  private

  def find_or_create_daily_frequencies
    @daily_frequencies = []
    if @class_numbers.present?
      @class_numbers.each do |class_number|
        @daily_frequencies << find_or_create_daily_frequency(@params.merge({class_number: class_number}))
      end
    else
      @daily_frequencies << find_or_create_daily_frequency(@params)
    end
  end

  def find_or_create_daily_frequency(params)
    begin
      DailyFrequency.find_or_create_by!(params)
    rescue ActiveRecord::RecordNotUnique
      DailyFrequency.find_by(params)
    end
  end

  def find_or_create_daily_frequency_students
    fetch_student_enrollments

    @student_enrollments.each do |student_enrollment|
      student = student_enrollment.student
      dependence = student_has_dependence?(student_enrollment.id, first_daily_frequency.discipline_id)
      @daily_frequencies.each do |daily_frequency|
        find_or_create_daily_frequency_student(daily_frequency, student, dependence)
      end
    end
  end

  def find_or_create_daily_frequency_student(daily_frequency, student, dependence)
    begin
      daily_frequency.students.find_or_create_by(student_id: student.id) do |daily_frequency_student|
        daily_frequency_student.dependence = dependence
        daily_frequency_student.present = true
        daily_frequency_student.active = true
      end
    rescue ActiveRecord::RecordNotUnique
    end
  end

  def fetch_student_enrollments
    @student_enrollments = StudentEnrollment
      .includes(:student)
      .by_classroom(first_daily_frequency.classroom)
      .by_discipline(first_daily_frequency.discipline)
      .by_date(@params[:frequency_date])
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
