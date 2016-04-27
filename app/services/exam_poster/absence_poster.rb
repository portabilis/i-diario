module ExamPoster
  class AbsencePoster < Base
    def self.post!(post_data)
      new(post_data).post!
    end

    def post!
      post_general_classrooms.each do |key, value|
        api.send_post(faltas: { key => value }, etapa: @post_data.school_calendar_step.to_number, resource: 'faltas-geral')
      end

      post_by_discipline_classrooms.each do |classroom_id, classroom_absence|
        classroom_absence.each do |student_id, student_absence|
          student_absence.each do |discipline_id, discipline_absence|
            api.send_post(faltas: { classroom_id => { student_id => { discipline_id => discipline_absence } } }, etapa: @post_data.school_calendar_step.to_number, resource: 'faltas-por-componente')
          end
        end
      end

      return { warning_messages: @warning_messages }
    end

    protected

    def api
      IeducarApi::PostAbsences.new(@post_data.to_api)
    end

    def post_general_classrooms
      absences = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next if classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
        next if classroom.exam_rule.frequency_type != FrequencyTypes::GENERAL

        daily_frequencies = DailyFrequency
          .by_classroom_id(classroom.id)
          .by_frequency_date_between(step_start_at, step_end_at)
          .general_frequency

        students = fetch_students(daily_frequencies)

        students.each do |student|
          daily_frequency_students = DailyFrequencyStudent.general_by_classroom_student_date_between(
            classroom,
            student.id,
            step_start_at,
            step_end_at
          )
          value = daily_frequency_students.absences.count
          absences[classroom.api_code][student.api_code]['valor'] = value
        end
      end

      absences
    end

    def post_by_discipline_classrooms
      absences = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          next if teacher_discipline_classroom.classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
          next if classroom.exam_rule.frequency_type != FrequencyTypes::BY_DISCIPLINE

          discipline = teacher_discipline_classroom.discipline

          daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
            .by_discipline_id(discipline.id)
            .by_frequency_date_between(step_start_at, step_end_at)

          if daily_frequencies.any?
            students = fetch_students(daily_frequencies)

            students.each do |student|
              daily_frequency_students = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
                classroom.id,
                discipline.id,
                student.id,
                step_start_at,
                step_end_at
              )

              if daily_frequency_students.any?
                value = daily_frequency_students.absences.count
                absences[classroom.api_code][student.api_code][discipline.api_code]['valor'] = value
              end
            end
          end
        end
      end
      absences
    end

    private

    def step_start_at
      @post_data.school_calendar_step.start_at
    end

    def step_end_at
      @post_data.school_calendar_step.end_at
    end

    def teacher
      @post_data.author.teacher
    end

    def fetch_students(daily_frequencies)
      students_ids = []
      daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
      students_ids.flatten!.uniq! if students_ids.any?
      Student.find(students_ids)
    end
  end

end
