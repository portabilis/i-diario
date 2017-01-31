module DailyFrequencyHelper
  def params_for_print_month daily_frequencies
    daily_frequency = daily_frequencies[0]
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: (1..@number_of_classes).to_a.join(","),
      start_at: l(daily_frequency.frequency_date.at_beginning_of_month),
      end_at: l(daily_frequency.frequency_date.end_of_month),
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id
    }
  end

  def params_for_print_step daily_frequencies
    daily_frequency = daily_frequencies[0]
    start_at = get_start_at(daily_frequency)
    end_at = get_end_at(daily_frequency)
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: (1..@number_of_classes).to_a.join(","),
      start_at: l(start_at),
      end_at: l(end_at),
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id
    }
  end

  def get_start_at(daily_frequency)
    if daily_frequency.classroom.calendar
      get_school_calendar_classroom_step(daily_frequency).start_at
    else
      get_school_calendar_step(daily_frequency).start_at
    end
  end

  def get_end_at(daily_frequency)
    if daily_frequency.classroom.calendar
      get_school_calendar_classroom_step(daily_frequency).end_at
    else
      get_school_calendar_step(daily_frequency).end_at
    end
  end

  def get_school_calendar_step(daily_frequency)
    daily_frequency.school_calendar.step(daily_frequency.frequency_date)
  end

  def get_school_calendar_classroom_step(daily_frequency)
    daily_frequency.school_calendar.classrooms.by_classroom(daily_frequency.classroom_id).first.classroom_step(daily_frequency.frequency_date)
  end

  def frequency_student_name_class(dependence, active)
    if !active
      'inactive-student'
    elsif dependence
      'dependence-student'
    else
      ''
    end
  end

  def frequency_student_name(student, dependence, active)
    if !active
      "**#{student.to_s}"
    elsif dependence
      "*#{student.to_s}"
    else
      "#{student.to_s}"
    end
  end
end
