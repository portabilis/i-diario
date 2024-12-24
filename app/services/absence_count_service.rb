class AbsenceCountService
  def initialize(do_not_send_justified_absence)
    @do_not_send_justified_absence = do_not_send_justified_absence
  end

  def count(student, classroom, start_date, end_date, discipline = nil)
    unless classroom.period == Periods::FULL
      return student_frequencies_in_date_range(student, classroom, start_date, end_date, discipline).absences.count
    end

    grouped_frequencies_by_date(student, classroom, start_date, end_date, discipline).sum { |_key, value|
      if discipline
        value[:absence_count]
      elsif value[:presence_count].zero? && value[:absence_count] >= 1
        1
      else
        0
      end
    }
  end

  private

  def student_frequencies_in_date_range(student, classroom, start_date, end_date, discipline)
    if discipline
      daily_frequency_student = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
        classroom.id,
        discipline.id,
        student.id,
        start_date,
        end_date
      ).active
    else
      daily_frequency_student = DailyFrequencyStudent.general_by_classroom_student_date_between(
        classroom,
        student.id,
        start_date,
        end_date
      ).active
    end

    if @do_not_send_justified_absence
      daily_frequency_student = daily_frequency_student.by_not_justified
    end

    daily_frequency_student
  end

  def grouped_frequencies_by_date(student, classroom, start_date, end_date, discipline)
    frequecies_by_date = student_frequencies_in_date_range(student, classroom, start_date, end_date, discipline).group_by { |daily_frequency_student|
      daily_frequency_student.daily_frequency.frequency_date
    }

    daily_frequencies = create_hash

    frequecies_by_date.each do |frequency_date, daily_frequency_students|
      frequencies = count_frequencies(daily_frequency_students, discipline)
      daily_frequencies[frequency_date] = {
        presence_count: frequencies[:presences],
        absence_count: frequencies[:absences]
      }
    end

    daily_frequencies
  end

  def count_frequencies(daily_frequency_students, discipline)
    frequencies = create_hash
    presences = absences = 0

    daily_frequency_students = unify_same_component_frequencies(daily_frequency_students) if discipline

    daily_frequency_students.each do |frequency|
      presences += 1 if frequency.present
      absences += 1 unless frequency.present
    end

    frequencies[:presences] = presences
    frequencies[:absences] = absences

    frequencies
  end

  def unify_same_component_frequencies(daily_frequency_students)
    grouped_frequencies_by_class_number = daily_frequency_students.group_by { |daily_frequency_student|
      daily_frequency_student.daily_frequency.class_number
    }

    grouped_frequencies_by_class_number.each do |_key, frequencies|
      next if frequencies.size == 1

      if (presence = frequencies.find(&:present))
        daily_frequency_students.delete_if { |daily_frequency_student|
          daily_frequency_student.id != presence.id
        }
      else
        daily_frequency_students.delete_if { |daily_frequency_student|
          daily_frequency_student.id != frequencies.first.id
        }
      end
    end

    daily_frequency_students
  end

  def create_hash
    Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  end
end
