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
    validate_parameters!(classroom_id, frequency_date, teacher_id)

    frequency_students = set_daily_frequency_students(classroom_id, frequency_date)

    return remove_unique_daily_frequency_students(classroom_id, frequency_date) if frequency_students.blank?

    hash_frequency_students = build_hash_frequency_students(frequency_students, classroom_id, frequency_date)

    create_or_update_unique_daily_frequency_students(hash_frequency_students, teacher_id)
  end

  private

  def set_daily_frequency_students(classroom_id, frequency_date)
    DailyFrequencyStudent.joins(:daily_frequency)
                         .where(
                            daily_frequencies: {
                              classroom_id: classroom_id, frequency_date: frequency_date
                            },
                           active: true
                          )
                         .pluck(:student_id, :present)
  end

  def build_hash_frequency_students(frequency_students, classroom_id, frequency_date)
    frequency_students.to_h.transform_values do |present|
      {
        classroom_id: classroom_id,
        frequency_date: frequency_date,
        present: present || false
      }
    end
  end

  # Random time between 19h and 23h
  # But at least at 1 minute after the current time
  def perform_worker_time
    [
      Date.current + rand(19...24).hours + rand(0...60).minutes + rand(0...60).seconds,
      1.minute.from_now
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

  def validate_parameters!(classroom_id, frequency_date, teacher_id)
    if classroom_id.blank? || frequency_date.blank? || teacher_id.blank?
      raise ArgumentError, "Parâmetros inválidos: classroom_id, frequency_date ou teacher_id não estão presentes"
    end
  end
end
