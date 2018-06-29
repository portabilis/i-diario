module ExamPoster
  class AbsencePoster < Base

    private

    def generate_requests
      post_general_classrooms.each do |classroom_id, classroom_absence|
        classroom_absence.each do |student_id, student_absence|
          self.requests << {
            etapa: @post_data.step.to_number,
            resource: 'faltas-geral',
            faltas: {
              classroom_id => {
                student_id => student_absence
              }
            }
          }
        end
      end

      post_by_discipline_classrooms.each do |classroom_id, classroom_absence|
        classroom_absence.each do |student_id, student_absence|
          student_absence.each do |discipline_id, discipline_absence|
            self.requests << {
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
          end
        end
      end
    end

    protected

    def api
      IeducarApi::PostAbsences.new(@post_data.to_api)
    end

    def post_general_classrooms
      absences = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next if classroom.unity_id != @post_data.step.school_calendar.unity_id
        next if classroom.exam_rule.frequency_type != FrequencyTypes::GENERAL
        next unless step_exists_for_classroom?(classroom)

        daily_frequencies = DailyFrequency
          .by_classroom_id(classroom.id)
          .by_frequency_date_between(step_start_at(classroom), step_end_at(classroom))
          .general_frequency

        students = fetch_students(daily_frequencies)

        students.each do |student|
          daily_frequency_students = DailyFrequencyStudent.general_by_classroom_student_date_between(
            classroom,
            student.id,
            step_start_at(classroom),
            step_end_at(classroom)
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
          next if teacher_discipline_classroom.classroom.unity_id != @post_data.step.school_calendar.unity_id
          next if classroom.exam_rule.frequency_type != FrequencyTypes::BY_DISCIPLINE
          next unless step_exists_for_classroom?(classroom)

          discipline = teacher_discipline_classroom.discipline

          daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
            .by_discipline_id(discipline.id)
            .by_frequency_date_between(step_start_at(classroom), step_end_at(classroom))

          if daily_frequencies.any?
            students = fetch_students(daily_frequencies)

            students.each do |student|
              daily_frequency_students = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
                classroom.id,
                discipline.id,
                student.id,
                step_start_at(classroom),
                step_end_at(classroom)
              ).active

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

    def step_start_at(classroom)
      step_start_at = @post_data.step.start_at
      if classroom.calendar
        classroom.calendar.classroom_steps.each do |classroom_step|
          if classroom_step.to_number == @post_data.step.to_number
            step_start_at = classroom_step.start_at
            break
          end
        end
      else
        school_calendar = SchoolCalendar.by_unity_id(classroom.unity_id).by_school_day(Time.zone.today).first

        school_calendar.steps.each do |school_step|
          if school_step.to_number == @post_data.step.to_number
            step_start_at = school_step.start_at
            break
          end
        end
      end

      step_start_at
    end

    def step_end_at(classroom)
      step_end_at = @post_data.step.end_at
      if classroom.calendar
        classroom.calendar.classroom_steps.each do |classroom_step|
          if classroom_step.to_number == @post_data.step.to_number
            step_end_at = classroom_step.end_at
            break
          end
        end
      else
        school_calendar = SchoolCalendar.by_unity_id(classroom.unity_id).by_school_day(Time.zone.today).first

        school_calendar.steps.each do |school_step|
          if school_step.to_number == @post_data.step.to_number
            step_end_at = school_step.end_at
            break
          end
        end
      end

      step_end_at
    end

    def fetch_students(daily_frequencies)
      students_ids = []
      daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
      students_ids.flatten!.uniq! if students_ids.any?
      Student.find(students_ids)
    end
  end

end
