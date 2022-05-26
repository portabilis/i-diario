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
  validates :discipline_id, presence: true, unless: :global_absence?
  validates :class_numbers, presence: true, unless: :global_absence?
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true
  validate :must_have_daily_frequencies

  def daily_frequencies
    if global_absence?
      DailyFrequency.by_classroom_id(classroom_id)
                    .by_period(period)
                    .by_frequency_date_between(start_at, end_at)
                    .general_frequency
                    .includes(students: :student)
                    .order_by_frequency_date
                    .order_by_class_number
                    .order_by_student_name

    else
      DailyFrequency.by_classroom_id(classroom_id)
                    .by_period(period)
                    .by_discipline_id(discipline_id)
                    .by_class_number(class_numbers.split(','))
                    .by_frequency_date_between(start_at, end_at)
                    .includes(students: :student)
                    .order_by_frequency_date
                    .order_by_class_number
                    .order_by_student_name
    end
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

  def students_enrollments
    adjusted_period = period != Periods::FULL ? period : nil

    StudentEnrollmentsList.new(
      classroom: classroom_id,
      discipline: discipline_id,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    ).student_enrollments
  end

  def students_frequencies_percentage
    percentage_by_student = {}

    absences_students.each do |student_id, absences_student|
      percentage = calculate_percentage(absences_student[:count_days], absences_student[:absences])
      percentage_by_student = percentage_by_student.merge({ student_id => percentage })
    end

    percentage_by_student
  end

  private

  def remove_duplicated_enrollments(students_enrollments)
    students_enrollments = students_enrollments.select do |student_enrollment|
      enrollments_for_student = StudentEnrollment.by_student(student_enrollment.student_id)
                                                 .by_classroom(classroom_id)

      if enrollments_for_student.count > 1
        enrollments_for_student.last != student_enrollment
      else
        true
      end
    end

    students_enrollments
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

    daily_frequencies.each do |daily_frequency|
      daily_frequency.students.each do |daily_frequency_student|
        student_id = daily_frequency_student.student_id

        count_days[student_id] ||= 0
        count_day = count_day?(daily_frequency, student_id)
        count_days[student_id] += 1 if count_day

        if !daily_frequency_student.present && count_day
          absences_by_student[student_id] ||= { :absences => 0, :count_days => 0 }
          absences_by_student[student_id][:absences] += 1
        end

        if absences_by_student.present? && absences_by_student[student_id]
          absences_by_student[student_id][:count_days] = count_days[student_id]
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
    student_enrollment = StudentEnrollment.by_classroom(daily_frequency.classroom_id)
                                          .by_student(student_id)
                                          .by_year(daily_frequency.classroom.year)
                                          .first
    frequency_date = daily_frequency.frequency_date

    return false if in_active_search?(student_enrollment, frequency_date) ||
      inactive_on_date?(daily_frequency, student_enrollment) ||
      exempted_from_discipline?(daily_frequency, student_enrollment)

    true
  end

  def active_search
    @active_search ||= ActiveSearch.new
  end

  def in_active_search?(student_enrollment, frequency_date)
    active_search.in_active_search?(student_enrollment.id, frequency_date)
  end

  def inactive_on_date?(daily_frequency, student_enrollment)
    StudentEnrollment.where(id: student_enrollment)
                     .by_classroom(daily_frequency.classroom)
                     .by_date(daily_frequency.frequency_date)
                     .empty?
  end

  def exempted_from_discipline?(daily_frequency, student_enrollment)
    return false if daily_frequency.discipline_id.blank?

    frequency_date = daily_frequency.frequency_date
    discipline_id = daily_frequency.discipline.id
    step_number = daily_frequency.school_calendar.step(frequency_date).try(:to_number)

    student_enrollment.exempted_disciplines
                      .by_discipline(discipline_id)
                      .by_step_number(step_number)
                      .any?
  end
end
