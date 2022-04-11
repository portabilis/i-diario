module DailyFrequencyHelper
  def params_for_print_month(daily_frequencies)
    daily_frequency = daily_frequencies[0]
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: (1..@number_of_classes).to_a.join(','),
      start_at: l(daily_frequency.frequency_date.at_beginning_of_month),
      end_at: l(daily_frequency.frequency_date.end_of_month),
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id,
      period: daily_frequency.period
    }
  end

  def params_for_print_step(daily_frequencies)
    daily_frequency = daily_frequencies[0]
    start_at = get_start_at(daily_frequency)
    end_at = get_end_at(daily_frequency)
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: (1..@number_of_classes).to_a.join(','),
      start_at: l(start_at),
      end_at: l(end_at),
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id,
      period: daily_frequency.period
    }
  end

  def get_start_at(daily_frequency)
    StepsFetcher.new(daily_frequency.classroom).step_by_date(daily_frequency.frequency_date).start_at
  end

  def get_end_at(daily_frequency)
    StepsFetcher.new(daily_frequency.classroom).step_by_date(daily_frequency.frequency_date).end_at
  end

  def frequency_student_name_class(dependence, active, exempted_from_discipline, in_active_search)
    name_class = 'multiline'

    if !active
      name_class += ' inactive-student'
    elsif dependence
      name_class += ' dependence-student'
    elsif exempted_from_discipline
      name_class += ' exempted-student-from-discipline'
    elsif in_active_search
      name_class += ' in-active-search'
    end

    name_class
  end

  def frequency_student_name(student, dependence, active, exempted_from_discipline, in_active_search)
    if !active
      "***#{student}"
    elsif dependence
      "*#{student}"
    elsif exempted_from_discipline
      "****#{student}"
    elsif in_active_search
      "*****#{student}"
    else
      student.to_s
    end
  end
end
