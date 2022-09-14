class DailyFrequencyQuery
  class << self
    def call(global_absence, discipline_id, classroom_id, period, class_numbers, start_at, end_at)
      daily_frequency = DailyFrequency.by_classroom_id(classroom_id)
                                      .by_period(period)
                                      .by_frequency_date_between(start_at, end_at)
                                      .includes([students: :student], :school_calendar, :discipline, :classroom, :unity)
                                      .order_by_frequency_date
                                      .order_by_class_number
                                      .order_by_student_name

      daily_frequency = by_general_frequency(daily_frequency, daily_frequency)
      daily_frequency = attendance_by_discipline(daily_frequency, global_absence, discipline_id, class_numbers)
      
      daily_frequency
    end

    private 

    def by_general_frequency(daily_frequency, global_absence)
      return daily_frequency unless global_absence

      daily_frequency.general_frequency
    end

    def attendance_by_discipline(daily_frequency, global_absence, discipline_id, class_numbers)
      return daily_frequency if global_absence.present?

      daily_frequency.by_discipline_id(discipline_id)
                    .by_class_number(class_numbers.split(','))
    end
  end
end