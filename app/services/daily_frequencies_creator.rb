class DailyFrequenciesCreator
  attr_reader :daily_frequencies

  def initialize(params)
    @params = params
    @class_numbers = params.delete(:class_numbers) || [nil]
    @origin = params.delete(:origin) || OriginTypes::API_V2
    @params[:frequency_date] ||= Time.zone.today
  end

  def self.find_or_create!(params)
    new(params).find_or_create!
  end

  def find_or_create!
    find_or_create_daily_frequencies
    find_or_create_daily_frequency_students
    true
  end

  private

  def find_or_create_daily_frequencies
    @daily_frequencies =
      @class_numbers.map do |class_number|
        daily_frequency = find_or_create_daily_frequency(@params.merge({class_number: class_number}))
        daily_frequency if daily_frequency.persisted?
      end.compact
  end

  def find_or_create_daily_frequency(params)
    DailyFrequency.create(params.merge(origin: @origin))
  rescue ActiveRecord::RecordNotUnique
    DailyFrequency.find_by(params)
  end

  def find_or_create_daily_frequency_students
    student_enrollments.each do |student_enrollment|
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

  def student_enrollments
    @student_enrollments ||=
      if first_daily_frequency.blank?
        []
      else
        StudentEnrollment.includes(:student)
                         .by_classroom(first_daily_frequency.classroom)
                         .by_discipline(first_daily_frequency.discipline)
                         .by_date(@params[:frequency_date])
                         .exclude_exempted_disciplines(first_daily_frequency.discipline_id, step_number)
                         .active
                         .ordered
      end
  end

  def first_daily_frequency
    @first_daily_frequency ||= @daily_frequencies[0]
  end

  def student_has_dependence?(student_enrollment_id, discipline_id)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment_id)
                               .by_discipline(discipline_id)
                               .any?
  end

  def step_number
    @step_number ||= first_daily_frequency.school_calendar.step(first_daily_frequency.frequency_date).try(:to_number) || 0
  end
end
