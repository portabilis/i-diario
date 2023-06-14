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
    DailyFrequency.create_with(
      params.slice(
        :unity_id,
        :school_calendar,
        :owner_teacher_id
      ).merge(
        origin: @origin
      )
    ).find_or_create_by(
      params.slice(
        :classroom_id,
        :frequency_date,
        :period,
        :discipline_id,
        :class_number
      )
    )
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def find_or_create_daily_frequency_students
    @daily_frequencies.each do |daily_frequency|
      not_student_ids = daily_frequency.students.map(&:student_id)
      student_enrollments = student_enrollments(not_student_ids)
      student_ids = student_enrollments.map(&:student_id)

      absence_justifications = AbsenceJustifiedOnDate.call(
        students: student_ids,
        date: daily_frequency.frequency_date,
        end_date: daily_frequency.frequency_date,
        classroom: daily_frequency.classroom_id,
        period: daily_frequency.period
      )

      student_enrollments.each do |student_enrollment|
        find_or_create_daily_frequency_student(daily_frequency, student_enrollment, absence_justifications)
      end
    end
  end

  def find_or_create_daily_frequency_student(daily_frequency, student_enrollment, absence_justifications)
    daily_frequency.students.find_or_create_by(student_id: student_enrollment.student_id) do |daily_frequency_student|
      absence_justification = absence_justifications[daily_frequency_student.student_id] || {}
      absence_justification = absence_justification[daily_frequency.frequency_date] || {}
      absence_justification_student_id = absence_justification[0] || absence_justification[daily_frequency.class_number]

      if absence_justification_student_id
        daily_frequency_student.present = false
        daily_frequency_student.absence_justification_student_id = absence_justification_student_id
      elsif
        daily_frequency_student.present = true
      end

      daily_frequency_student.dependence = student_has_dependence?(student_enrollment.id, first_daily_frequency.discipline_id)
      daily_frequency_student.active = true
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def student_enrollments(not_student_ids)
    @student_enrollments ||= begin
      if first_daily_frequency.blank?
        student_enrollments = []
      else
        student_enrollments = StudentEnrollment.includes(:student)
                                               .where.not(student_id: not_student_ids)
                                               .by_classroom(first_daily_frequency.classroom)
                                               .by_discipline(first_daily_frequency.discipline)
                                               .by_date(@params[:frequency_date])
                                               .exclude_exempted_disciplines(
                                                 first_daily_frequency.discipline_id,
                                                 step_number
                                               )
                                               .active
                                               .ordered

        student_enrollments.by_period(student_period) if student_period
      end

      student_enrollments
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
    @step_number ||= steps_fetcher.step_by_date(first_daily_frequency.frequency_date).try(:to_number) || 0
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(first_daily_frequency.classroom)
  end

  def student_period
    @params[:period] != Periods::FULL.to_i ? @params[:period] : nil
  end
end
