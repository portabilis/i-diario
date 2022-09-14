class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :period,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :school_calendar_year,
                :current_teacher_id,
                :school_calendar,
                :second_teacher_signature,
                :display_knowledge_area_as_discipline

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :discipline_id, presence: true, unless: :global_absence
  validates :class_numbers, presence: true, unless: :global_absence
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true
  validate :must_have_daily_frequencies

  def daily_frequencies
    @daily_frequencies ||= DailyFrequencyQuery.call(global_absence, discipline_id, classroom_id, period, class_numbers, start_at, end_at)
  end

  def school_calendar_events
    events_by_day = []
    events = school_calendar.events
                            .events_to_report
                            .by_date_between(start_at, end_at)
                            .all_events_for_classroom(classroom)
                            .where(
                              SchoolCalendarEvent.arel_table[:discipline_id].eq(nil).or(
                                SchoolCalendarEvent.arel_table[:discipline_id].eq(discipline_id)
                              )
                            )
                            .ordered

    events.each do |event|
      (event.start_date..event.end_date).each do |date|
        events_by_day << {
          date: date,
          legend: event.legend,
          description: event.description
        }
      end
    end
    events_by_day
  end

  def student_enrollment_list
    adjusted_period = period != Periods::FULL ? period : nil

    @students ||= StudentEnrollmentsList.new(
      classroom: classroom_id,
      discipline: discipline_id,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    ).student_enrollments(as_relation: true)
    @students_enrollments_array = @students.to_a
    @students
  end

  def students_frequencies_percentage
    percentage_by_student = {}

    absences_students.each do |student_enrollment_id, absences_student|
      percentage = calculate_percentage(absences_student[:count_days], absences_student[:absences])
      percentage_by_student = percentage_by_student.merge({ student_enrollment_id => percentage })
    end

    percentage_by_student
  end

  private

  def days_enrollment
    days = daily_frequencies.map(&:frequency_date)
    students_ids = daily_frequencies.map do |daily_frequency|
      daily_frequency.students.map(&:student_id)
    end.flatten.uniq

    EnrollmentFromStudentFetcher.new.current_enrollments(students_ids, classroom_id, days)
  end


  def global_absence
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher, year: classroom.year)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::GENERAL
  end

  def must_have_daily_frequencies
    return if errors.present?

    errors.add(:daily_frequencies, :must_have_daily_frequencies) if daily_frequencies.count.zero?
  end

  def classroom
    Classroom.find(@classroom_id)
  end

  def teacher
    Teacher.find(@current_teacher_id)
  end

  def absences_students
    absences_by_student = {}
    count_days = {}
    enrollments = days_enrollment

    daily_frequencies.each do |daily_frequency|
      daily_frequency.students.each do |daily_frequency_student|
        student_id = daily_frequency_student.student.id
        student_enrollment_id = enrollments[student_id][daily_frequency.frequency_date] if enrollments[student_id]

        next if student_enrollment_id.nil?

        count_days[student_id] ||= 0
        count_day = count_day?(daily_frequency, student_id)
        count_days[student_id] += 1 if count_day
        absence = !daily_frequency_student.present

        if absence && count_day
          absences_by_student[student_enrollment_id] ||= { :absences => 0, :count_days => 0 }
          absences_by_student[student_enrollment_id][:absences] += 1
        end

        if absences_by_student.present? && absences_by_student[student_enrollment_id]
          absences_by_student[student_enrollment_id][:count_days] = count_days[student_id]
        end
      end
    end

    absences_by_student
  end

  def calculate_percentage(frequency_days, absences_student)
    total_percentage = 100
    multiplication = absences_student * total_percentage
    (total_percentage - (multiplication / frequency_days)).to_s + '%'
  end

  def count_day?(daily_frequency, student_id)
    frequency_date = daily_frequency.frequency_date

    return false if in_active_search?(student_id, frequency_date) ||
      inactive_on_date?(frequency_date, student_id) ||
      exempted_from_discipline?(daily_frequency, student_id)

    true
  end

  def in_active_search?(student_id, frequency_date)
    return false unless active_searches[student_id]

    unique_dates_for_student = active_searches[student_id].uniq

    unique_dates_for_student.include?(frequency_date)
  end

  def active_searches
    @active_searches ||= in_active_searches
  end

  def in_active_searches
    students_enrollments_ids = @students_enrollments_array.map(&:id)
    dates = daily_frequencies.pluck(:frequency_date).uniq

    active_searches = {}

    ActiveSearch.new.in_active_search_in_range(students_enrollments_ids, dates).each do |active_search|
      next if active_search[:student_ids].blank?

      active_search[:student_ids].each do |student_id|
        active_searches[student_id] ||= []
        active_searches[student_id] << active_search[:date]
      end
    end

    active_searches
  end

  def inactive_on_date?(frequency_date, student_id)
    return false unless inactives[student_id]

    unique_dates_for_student = inactives[student_id].uniq

    unique_dates_for_student.include?(frequency_date)
  end

  def inactives
    @inactives ||= inactives_on_dates
  end

  def inactives_on_dates
    inactives_on_dates = {}

    daily_frequencies.each do |daily_frequency|
      enrollments_ids = @students_enrollments_array.map(&:id)
      enrollments_on_date = StudentEnrollment.where(id: enrollments_ids)
                                             .by_date(daily_frequency.frequency_date)
      enrollments_on_date_ids = enrollments_on_date.pluck(:id)
      not_enrrolled_on_the_date = enrollments_ids - enrollments_on_date_ids

      next if not_enrrolled_on_the_date.empty?

      not_enrrolled_on_the_date.each do |not_enrolled|
        enrollment = @students_enrollments_array.select { |student_enrollment| student_enrollment.id == not_enrolled }.first
        inactives_on_dates[enrollment.student_id] ||= []
        inactives_on_dates[enrollment.student_id] << daily_frequency.frequency_date
      end
    end

    inactives_on_dates
  end

  def exempted_from_discipline?(daily_frequency, student_id)
    return false if exempts.empty?

    step = daily_frequency.school_calendar.step(daily_frequency.frequency_date).try(:to_number)

    return false if exempts[student_id].nil?

    exempts[student_id].include?(step)
  end

  def exempts
    @exempts ||= exempts_data
  end

  def exempts_data
    return {} if daily_frequencies.first.discipline_id.blank?

    discipline_id = daily_frequencies.first.discipline_id
    enrollments_ids = @students_enrollments_array.map(&:id)
    exempteds_from_discipline = {}

    steps = daily_frequencies.map { |daily_frequency|
      daily_frequency.school_calendar.step(daily_frequency.frequency_date).try(:to_number)
    }

    unique_steps = steps.uniq

    unique_steps.each do |step_number|
      StudentEnrollmentExemptedDiscipline.by_discipline(discipline_id)
                                         .by_step_number(step_number)
                                         .by_student_enrollment(enrollments_ids)
                                         .includes(student_enrollment: [:student])
                                         .each do |student_exempted|
        exempteds_from_discipline[student_exempted.student_enrollment.student_id] ||= []
        exempteds_from_discipline[student_exempted.student_enrollment.student_id] << step_number
      end
    end

    exempteds_from_discipline
  end
end
