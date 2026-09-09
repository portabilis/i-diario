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

  # Um worker por professor que lançou na turma/dia: dois professores geram dois workers que
  # disputariam o INSERT de cada aluno e um deles violaria o índice único. O lock por turma/dia
  # faz o segundo esperar o primeiro terminar e encontrar os registros que o primeiro já criou.
  def create!(classroom_id, frequency_date, teacher_id)
    validate_parameters!(classroom_id, frequency_date, teacher_id)

    AdvisoryTransactionLock.call(lock_key(classroom_id, frequency_date)) do
      frequency_students = set_daily_frequency_students(classroom_id, frequency_date)

      next remove_unique_daily_frequency_students(classroom_id, frequency_date) if frequency_students.blank?

      hash_frequency_students = build_hash_frequency_students(frequency_students, classroom_id, frequency_date)

      create_or_update_unique_daily_frequency_students(hash_frequency_students, classroom_id, teacher_id)
    end
  end

  private

  # Os argumentos chegam do Sidekiq serializados em JSON; o cast faz texto e Date, ou texto e inteiro,
  # gerarem a mesma chave.
  def lock_key(classroom_id, frequency_date)
    values = %w[classroom_id frequency_date].zip([classroom_id, frequency_date]).map do |column, value|
      UniqueDailyFrequencyStudent.type_for_attribute(column).cast(value)
    end

    ['unique_daily_frequency_students', *values].join(':')
  end

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

  # O vínculo do professor com a turma não varia entre os alunos: uma consulta antes do laço, e não
  # uma por aluno dentro da transação que segura o lock. Sem o vínculo nada é gravado, e o log é o
  # que distingue isso de "o worker não rodou" — que é como o caso chega ao suporte.
  def create_or_update_unique_daily_frequency_students(daily_frequency_students, classroom_id, teacher_id)
    unless teacher_lesson_on_classroom?(teacher_id, classroom_id)
      Rails.logger.info(
        "[#{self.class}] nenhum registro gravado: professor #{teacher_id} não tem vínculo " \
        "com a turma #{classroom_id}"
      )

      return
    end

    daily_frequency_students.each do |student_id, frequency_data|
      UniqueDailyFrequencyStudent.find_or_initialize_by(
        student_id: student_id,
        classroom_id: frequency_data[:classroom_id],
        frequency_date: frequency_data[:frequency_date]
      ).tap do |unique_daily_frequency_student|
        unique_daily_frequency_student.present = frequency_data[:present]
        unique_daily_frequency_student.absences_by |= [teacher_id.to_s] unless frequency_data[:present]

        unique_daily_frequency_student.save! if unique_daily_frequency_student.changed?
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
