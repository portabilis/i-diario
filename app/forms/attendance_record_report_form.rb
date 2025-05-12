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
                :second_teacher_signature

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :discipline_id, presence: true, unless: :global_absence?
  validates :class_numbers, presence: true, unless: :global_absence?
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true
  validate :must_have_daily_frequencies

  def daily_frequencies
    @daily_frequencies ||= fetch_daily_frequencies
  end

  def fetch_daily_frequencies
    DailyFrequencyQuery.call(
      classroom_id: classroom_id,
      period: period,
      frequency_date: start_at..end_at,
      discipline_id: !global_absence? && discipline_id,
      class_numbers: !global_absence? && class_numbers
    ).group_by(&:frequency_date).map do |frequency_date, frequencies|
      if frequencies.map(&:class_number).uniq.size > 1
        frequencies
      else
        daily_frequency = frequencies.find { |f| f.period == Periods::FULL.to_i }
        daily_frequency || frequencies.first
      end
    end.flatten
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
          description: event.description,
          type: event.event_type
        }
      end
    end
    events_by_day
  end

  def enrollment_classrooms_list
    adjusted_period = period != Periods::FULL ? period : nil

    @enrollment_classrooms_list ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom_id,
      disciplines: discipline_id,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    )
  end

  def student_enrollment_ids
    @student_enrollment_ids ||= @enrollment_classrooms_list.map { |student_enrollment|
      student_enrollment[:student_enrollment].id
    }
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

    students_ids = daily_frequencies.flat_map(&:students).map(&:student_id).uniq

    EnrollmentFromStudentFetcher.new.current_enrollments(students_ids, classroom_id, days)
  end

  def global_absence?
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
    @do_not_send_justified_absence = GeneralConfiguration.current.do_not_send_justified_absence

    daily_frequencies.each do |daily_frequency|
      daily_frequency.students.each do |daily_frequency_student|
        next if daily_frequency_student.student.nil?

        student_id = daily_frequency_student.student.id
        student_enrollment_id = enrollments[student_id][daily_frequency.frequency_date] if enrollments[student_id]

        next if student_enrollment_id.nil?

        count_days[student_id] ||= 0
        count_day = count_day?(daily_frequency, student_enrollment_id)
        count_days[student_id] += 1 if count_day
        absence = !daily_frequency_student.present
        absence_justification = daily_frequency_student.absence_justification_student_id

        if absence && count_day
          absences_by_student[student_enrollment_id] ||= { :absences => 0, :count_days => 0 }

          if apply_absence?(absence_justification)
            absences_by_student[student_enrollment_id][:absences] += 1
          end
        end

        if absences_by_student.present? && absences_by_student[student_enrollment_id]
          absences_by_student[student_enrollment_id][:count_days] = count_days[student_id]
        end
      end
    end

    absences_by_student
  end

  def apply_absence?(absence_justification)
    true unless @do_not_send_justified_absence && absence_justification.present?
  end

  def calculate_percentage(frequency_days, absences_student)
    total_percentage = 100
    multiplication = absences_student * total_percentage
    (total_percentage - (multiplication / frequency_days)).to_s + '%'
  end

  def count_day?(daily_frequency, student_enrollment)
    frequency_date = daily_frequency.frequency_date

    return false if in_active_search?(student_enrollment, frequency_date) ||
                    inactive_on_date?(frequency_date, student_enrollment) ||
                    exempted_from_discipline?(daily_frequency, student_enrollment)

    true
  end

  def in_active_search?(student_enrollment, frequency_date)
    return false unless active_searches[student_enrollment]

    unique_dates_for_student = active_searches[student_enrollment].uniq

    unique_dates_for_student.include?(frequency_date)
  end

  def active_searches
    @active_searches ||= in_active_searches
  end

  def in_active_searches
    dates = daily_frequencies.map(&:frequency_date).uniq

    active_searches = {}

    ActiveSearch.new.in_active_search_in_range(student_enrollment_ids, dates).each do |active_search|
      next if active_search[:student_id].blank?

      active_search[:student_id].each do |student|
        active_searches[student] ||= []
        active_searches[student] << active_search[:date]
      end
    end

    active_searches
  end

  def inactive_on_date?(frequency_date, student_enrollment)
    return false unless inactives[student_enrollment]

    unique_dates_for_student = inactives[student_enrollment].uniq

    unique_dates_for_student.include?(frequency_date)
  end

  def inactives
    @inactives ||= inactives_on_dates
  end

  def inactives_on_dates
    inactives_on_dates = {}

    daily_frequencies.each do |daily_frequency|
      frequency_date = daily_frequency.frequency_date

      enrollments_on_date = @enrollment_classrooms_list.select { |enrollment_classroom|
        joined_at = enrollment_classroom[:student_enrollment_classroom].joined_at.to_date
        left_at = enrollment_classroom[:student_enrollment_classroom].left_at

        left_at = left_at.empty? ? Date.current.end_of_year : left_at.to_date

        frequency_date >= joined_at && frequency_date < left_at
      }

      enrollments_on_date_ids = enrollments_on_date.map { |enrollment| enrollment[:student_enrollment].id }
      not_enrrolled_on_the_date = student_enrollment_ids - enrollments_on_date_ids

      next if not_enrrolled_on_the_date.empty?

      not_enrrolled_on_the_date.each do |not_enrolled|
        enrollment = student_enrollment_ids.select { |student_enrollment| student_enrollment == not_enrolled }.first
        inactives_on_dates[enrollment] ||= []
        inactives_on_dates[enrollment] << daily_frequency.frequency_date
      end
    end

    inactives_on_dates
  end

  def exempted_from_discipline?(daily_frequency, student_enrollment)
    return false if exempts.empty?

    step = daily_frequency.school_calendar.step(daily_frequency.frequency_date).try(:to_number)

    return false if exempts[student_enrollment].nil?

    exempts[student_enrollment].include?(step)
  end

  def exempts
    @exempts ||= exempts_data
  end

  def exempts_data
    return {} if daily_frequencies.first.discipline_id.blank?

    discipline_id = daily_frequencies.first.discipline_id
    enrollments_ids = student_enrollment_ids
    exempteds_from_discipline = {}

    steps = daily_frequencies.map { |daily_frequency|
      daily_frequency.school_calendar.step(daily_frequency.frequency_date).try(:to_number)
    }

    unique_steps = steps.uniq

    unique_steps.each do |step_number|
      StudentEnrollmentExemptedDiscipline.by_discipline(discipline_id)
                                         .by_step_number(step_number)
                                         .by_student_enrollment(enrollments_ids)
                                         .includes(:student_enrollment)
                                         .each do |student_exempted|
        exempteds_from_discipline[student_exempted.student_enrollment] ||= []
        exempteds_from_discipline[student_exempted.student_enrollment] << step_number
      end
    end

    exempteds_from_discipline
  end
end
