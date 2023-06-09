class UniqueDailyFrequencyStudentsCreator
  def self.call_worker(entity_id, classroom_id, frequency_date, teacher_id)
    new.call_worker(entity_id, classroom_id, frequency_date, teacher_id)
  end

  def self.create!(classroom_id, frequency_date, teacher_id)
    new.create!(classroom_id, frequency_date, teacher_id)
  end

  def call_worker(entity_id, classroom_id, frequency_date, teacher_id)
    UniqueDailyFrequencyStudentsCreatorWorker.perform_at(
      perform_worker_time,
      entity_id,
      classroom_id,
      frequency_date,
      teacher_id
    )
  end

  def create!(classroom_id, frequency_date, teacher_id)
    daily_frequency_students = {}
    daily_frequencies = DailyFrequency.by_classroom_id(classroom_id)
                                      .by_frequency_date(frequency_date)
                                      .by_teacher_discipline_classroom(teacher_id, classroom_id)

    if daily_frequencies.present?
      daily_frequencies.each do |current_daily_frequency|
        current_daily_frequency.students.each do |student|
          daily_frequency_students[student.student_id] ||= {}
          daily_frequency_students[student.student_id][:present] = student.present || false
          daily_frequency_students[student.student_id].reverse_merge!(
            classroom_id: classroom_id,
            frequency_date: frequency_date
          )
        end
      end

      create_or_update_unique_daily_frequency_students(daily_frequency_students, teacher_id)
    else
      remove_unique_daily_frequency_students(classroom_id, frequency_date)
    end
  end

  private

  # Random time between 19h and 23h
  # But at least at 1 minute after the current time
  def perform_worker_time
    [
      Date.current + rand(19...24).hours + rand(0...60).minutes + rand(0...60).seconds,
      Time.current + 1.minute
    ].max
  end

  def teacher_lesson_on_classroom?(teacher_id, classroom_id)
    TeacherDisciplineClassroom.where(teacher_id: teacher_id, classroom_id: classroom_id).exists?
  end

  def create_or_update_unique_daily_frequency_students(daily_frequency_students, teacher_id)
    daily_frequency_students.each do |student_id, frequency_data|
      begin
        next unless teacher_lesson_on_classroom?(teacher_id, frequency_data[:classroom_id])

        UniqueDailyFrequencyStudent.find_or_initialize_by(
          student_id: student_id,
          classroom_id: frequency_data[:classroom_id],
          frequency_date: frequency_data[:frequency_date]
        ).tap do |unique_daily_frequency_student|
          unique_daily_frequency_student.present = frequency_data[:present]
          unique_daily_frequency_student.absences_by |= [teacher_id.to_s] unless frequency_data[:present]

          unique_daily_frequency_student.save! if unique_daily_frequency_student.changed?
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end

  def remove_unique_daily_frequency_students(classroom_id, frequency_date)
    UniqueDailyFrequencyStudent.by_classroom_id(classroom_id)
                               .frequency_date(frequency_date)
                               .destroy_all
  end
end
