module DailyFrequencyHelper
  def params_for_print_month daily_frequencies
    daily_frequency = daily_frequencies[0]
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: daily_frequencies.map(&:class_number).join(","),
      start_at: daily_frequency.frequency_date.at_beginning_of_month,
      end_at: daily_frequency.frequency_date.end_of_month,
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id
    }
  end

  def params_for_print_step daily_frequencies
    daily_frequency = daily_frequencies[0]
    {
      unity_id: daily_frequency.unity_id,
      classroom_id: daily_frequency.classroom_id,
      discipline_id: daily_frequency.discipline_id,
      class_numbers: daily_frequencies.map(&:class_number).join(","),
      start_at: daily_frequency.school_calendar.step(daily_frequency.frequency_date).start_at,
      end_at: daily_frequency.school_calendar.step(daily_frequency.frequency_date).end_at,
      school_calendar_year: daily_frequency.frequency_date.year,
      current_teacher_id: current_teacher.id
    }
  end
end
