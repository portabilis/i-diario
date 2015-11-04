class AbsencePosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    classrooms = post_general_classrooms
    if classrooms.any?
      api.send_post(turmas: classrooms, etapa: posting.school_calendar_step.to_number, resource: 'faltas-geral')
    end

    classrooms = post_by_discipline_classrooms
    if classrooms.any?
      api.send_post(turmas: classrooms, etapa: posting.school_calendar_step.to_number, resource: 'faltas-por-componente')
    end
  end

  protected

  attr_accessor :posting

  def api
    IeducarApi::PostAbsences.new(posting.to_api)
  end

  def post_general_classrooms
    classrooms = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.classrooms.uniq.each do |classroom|
      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      frequency_type = classroom.exam_rule.frequency_type
      if frequency_type != FrequencyTypes::GENERAL
        next
      end

      step_start_at = posting.school_calendar_step.start_at
      step_end_at = posting.school_calendar_step.end_at

      daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
        .by_frequency_date_between(step_start_at, step_end_at)

      if daily_frequencies.blank? || daily_frequencies.count != posting.school_calendar_step.number_of_school_days
        warning_dates = posting.school_calendar_step.school_day_dates

        if daily_frequencies.present?
          daily_frequencies.each do |daily_frequency|
            warning_dates.delete daily_frequency.frequency_date
          end
        end

        string_warning_dates = warning_dates.collect { |date| I18n.l(date) }.join(', ')
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as faltas da turma #{classroom} pois existem aulas que não foram lançadas no diário de frequência. Datas: #{string_warning_dates}.")
      else
        students_ids = []
        daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
        students_ids.flatten!.uniq! if students_ids.any?
        students = Student.find(students_ids)

        students.each do |student|
          daily_frequency_students = DailyFrequencyStudent.general_by_classroom_student_date_between(
            classroom,
            student.id,
            step_start_at,
            step_end_at
          )

          classrooms[classroom.api_code]['turma_id'] = classroom.api_code
          classrooms[classroom.api_code]['alunos'][student.api_code]['aluno_id'] = student.api_code
          classrooms[classroom.api_code]['alunos'][student.api_code]['faltas'] = daily_frequency_students.absences.count
        end
      end
    end

    classrooms
  end

  def post_by_discipline_classrooms
    classrooms = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      frequency_type = classroom.exam_rule.frequency_type
      if frequency_type != FrequencyTypes::BY_DISCIPLINE
        next
      end

      step_start_at = posting.school_calendar_step.start_at
      step_end_at = posting.school_calendar_step.end_at

      daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
        .by_discipline_id(discipline.id)
        .by_frequency_date_between(step_start_at, step_end_at)

      if daily_frequencies.any?
        students_ids = []
        daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
        students_ids.flatten!.uniq! if students_ids.any?
        students = Student.find(students_ids)

        students.each do |student|
          daily_frequency_students = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
            classroom.id,
            discipline.id,
            student.id,
            step_start_at,
            step_end_at
          )

          if daily_frequency_students.any?
            classrooms[classroom.api_code]['turma_id'] = classroom.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['aluno_id'] = student.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['componente_curricular_id'] = discipline.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['faltas'] = daily_frequency_students.absences.count
          end
        end
      end
    end

    classrooms
  end
end
