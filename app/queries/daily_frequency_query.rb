class DailyFrequencyQuery
  def self.call(filters = {})
    DailyFrequency.all.extending(Scopes)
      .by_classroom_id(filters[:classroom_id])
      .by_period(filters[:period])
      .by_frequency_date_between(filters[:frequency_date])
      .by_discipline_id(filters[:discipline_id], filters[:all_students_frequencies])
      .by_class_number(filters[:class_numbers], filters[:all_students_frequencies])
      .includes([students: :student], :school_calendar, :discipline, :classroom, :unity)
  end

  module Scopes
    def by_classroom_id(classroom_id)
      return self if classroom_id.blank?

      where(classroom_id: classroom_id)
    end

    def by_period(period)
      return self if period.blank?

      if period.eql?(Periods::FULL)
        where(period: [Periods::FULL, Periods::MATUTINAL, Periods::VESPERTINE, Periods::NIGHTLY])
      else
        where(period: period)
      end
    end

    def by_frequency_date_between(frequency_date)
      return self if frequency_date.blank?

      where(frequency_date: frequency_date)
    end

    def by_discipline_id(discipline_id, all_students_frequencies = false)
      return self if all_students_frequencies
      return self.where(discipline_id: nil) if discipline_id.blank?

      where(discipline_id: discipline_id)
    end

    def by_class_number(class_numbers, all_students_frequencies = false)
      return self if all_students_frequencies
      return self.where(class_number: nil) if class_numbers.blank?

      array_class_numbers = class_numbers.split(',')

      where(class_number: array_class_numbers)
    end
  end
end
