module ExamPoster
  class AbsencePoster < Base
    private

    def generate_requests
      post_general_classrooms.each do |classroom_id, classroom_absence|
        classroom_absence.each do |student_id, student_absence|
          requests << {
            info: {
              classroom: classroom_id,
              student: student_id
            },
            request: {
              etapa: @post_data.step.to_number,
              resource: 'faltas-geral',
              faltas: {
                classroom_id => {
                  student_id => student_absence
                }
              }
            }
          }
        end
      end

      post_by_discipline_classrooms.each do |classroom_id, classroom_absence|
        classroom_absence.each do |student_id, student_absence|
          student_absence.each do |discipline_id, discipline_absence|
            requests << {
              info: {
                classroom: classroom_id,
                student: student_id,
                discipline: discipline_id
              },
              request: {
                etapa: @post_data.step.to_number,
                resource: 'faltas-por-componente',
                faltas: {
                  classroom_id => {
                    student_id => {
                      discipline_id => discipline_absence
                    }
                  }
                }
              }
            }
          end
        end
      end
    end

    protected

    def post_general_classrooms
      absences = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      absence_count_service = AbsenceCountService.new(
        GeneralConfiguration.current.do_not_send_justified_absence
      )

      teacher.classrooms.uniq.each do |classroom|
        next unless can_post?(classroom)
        next if frequency_by_discipline?(classroom)

        start_date = step_start_at(classroom)
        end_date = step_end_at(classroom)

        daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
                                          .by_frequency_date_between(start_date,end_date)
                                          .general_frequency

        students = fetch_students(daily_frequencies)

        students.each do |student|
          next unless not_posted?({ classroom: classroom, student: student })[:absence]

          value = absence_count_service.count(student, classroom, start_date, end_date)

          absences[classroom.api_code][student.api_code]['valor'] = value
        end
      end

      absences
    end

    def post_by_discipline_classrooms
      absences = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      absence_count_service = AbsenceCountService.new(
        GeneralConfiguration.current.do_not_send_justified_absence
      )

      teacher.classrooms.uniq.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          next unless can_post?(classroom)
          next unless classroom_frequency_by_discipline?(classroom)

          discipline = teacher_discipline_classroom.discipline
          start_date = step_start_at(classroom)
          end_date = step_end_at(classroom)

          daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
                                            .by_discipline_id(discipline.id)
                                            .by_frequency_date_between(
                                              start_date,
                                              end_date
                                            )

          next unless daily_frequencies.any?

          students = fetch_students(daily_frequencies)

          students.each do |student|
            next unless not_posted?({ classroom: classroom, discipline: discipline, student: student })[:absence]

            value = absence_count_service.count(student, classroom, start_date, end_date, discipline)

            knowledge_area = discipline.grouper? ? discipline.knowledge_area.api_code.to_i : nil
            knowledge_area = knowledge_area.eql?(0) ? nil : knowledge_area

            absences[classroom.api_code][student.api_code][discipline.api_code]['valor'] = value
            absences[classroom.api_code][student.api_code][discipline.api_code]['area_do_conhecimento'] = knowledge_area
          end
        end
      end
      absences
    end

    private

    def step_start_at(classroom)
      step_start_at = get_step(classroom).start_at
      if classroom.calendar
        classroom.calendar.classroom_steps.each do |classroom_step|
          if classroom_step.to_number == get_step(classroom).to_number
            step_start_at = classroom_step.start_at
            break
          end
        end
      else
        school_calendar = SchoolCalendar.by_unity_id(classroom.unity_id)
                                        .by_year(classroom.year)
                                        .first

        school_calendar.steps.each do |school_step|
          if school_step.to_number == get_step(classroom).to_number
            step_start_at = school_step.start_at
            break
          end
        end
      end

      step_start_at
    end

    def step_end_at(classroom)
      step_end_at = get_step(classroom).end_at
      if classroom.calendar
        classroom.calendar.classroom_steps.each do |classroom_step|
          if classroom_step.to_number == get_step(classroom).to_number
            step_end_at = classroom_step.end_at
            break
          end
        end
      else
        school_calendar = SchoolCalendar.by_unity_id(classroom.unity_id)
                                        .by_year(classroom.year)
                                        .first

        school_calendar.steps.each do |school_step|
          if school_step.to_number == get_step(classroom).to_number
            step_end_at = school_step.end_at
            break
          end
        end
      end

      step_end_at
    end

    def fetch_students(daily_frequencies)
      students_ids = []
      daily_frequencies.each do |d|
        students_ids << d.students.map(&:student_id)
      end
      students_ids.flatten!.uniq! if students_ids.any?
      Student.find(students_ids)
    end

    def frequency_by_discipline?(classroom)
      FrequencyTypeDefiner.allow_frequency_by_discipline?(
        classroom,
        teacher
      )
    end

    def classroom_frequency_by_discipline?(classroom)
      classroom.first_exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
    end
  end
end
