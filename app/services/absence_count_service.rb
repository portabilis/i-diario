class AbsenceCountService
  def initialize(daily_frequency_students)
    @daily_frequency_students = daily_frequency_students
  end

  def count_absences
    absences = grouped_frequencies_by_date.map { |_, value|
      if value[:presence_count].zero?
        [1, 2].include?(value[:absence_count]) ? 1 : 0
      else
        0
      end
    }

    absences.reduce(:+)
  end

  def grouped_frequencies_by_date
    frequecies_by_date = @daily_frequency_students.group_by { |daily_frequency_student|
      daily_frequency_student.daily_frequency.frequency_date
    }

    daily_frequencies = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    frequecies_by_date.each do |frequency_date, daily_frequency_students|
      frequencies = count_frequencies(daily_frequency_students)
      daily_frequencies[frequency_date] = {
        presence_count: frequencies[:presences],
        absence_count: frequencies[:absences]
      }
    end

    daily_frequencies
  end

  def count_frequencies(daily_frequency_students)
    frequencies = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    presences = absences = 0

    daily_frequency_students.each do |frequency|
      frequency.present ? presences += 1 : absences += 1
    end

    frequencies[:presences] = presences
    frequencies[:absences] = absences

    frequencies
  end
end
