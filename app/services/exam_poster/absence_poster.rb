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

      teacher.classrooms.uniq.each do |classroom|
        next unless can_post?(classroom)
        next if frequency_by_discipline?(classroom)

        daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
                                          .by_frequency_date_between(
                                            step_start_at(classroom),
                                            step_end_at(classroom)
                                          )
                                          .general_frequency

        daily_frequencies_ids = repeated_frequencies(daily_frequencies, classroom)
        students = fetch_students(daily_frequencies)

        students.each do |student|
          daily_frequency_students = DailyFrequencyStudent.general_by_classroom_student_date_between(
            classroom,
            student.id,
            step_start_at(classroom),
            step_end_at(classroom)
          )

          if daily_frequencies_ids.present?
            frequencies_ids = define_frequencies(daily_frequencies_ids, daily_frequency_students, student)
            daily_frequency_students = daily_frequency_students.where.not(id: frequencies_ids)
          end

          value = daily_frequency_students.absences.count
          absences[classroom.api_code][student.api_code]['valor'] = value
        end
      end

      absences
    end

    def post_by_discipline_classrooms
      absences = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          next unless can_post?(classroom)
          next unless frequency_by_discipline?(classroom)

          discipline = teacher_discipline_classroom.discipline

          daily_frequencies = DailyFrequency.by_classroom_id(classroom.id)
                                            .by_discipline_id(discipline.id)
                                            .by_frequency_date_between(
                                              step_start_at(classroom),
                                              step_end_at(classroom)
                                            )

          next unless daily_frequencies.any?

          daily_frequencies_ids = repeated_frequencies(daily_frequencies, classroom, discipline)
          students = fetch_students(daily_frequencies)

          students.each do |student|
            daily_frequency_students = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
              classroom.id,
              discipline.id,
              student.id,
              step_start_at(classroom),
              step_end_at(classroom)
            ).active

            if daily_frequencies_ids.present?
              frequencies_ids = define_frequencies(daily_frequencies_ids, daily_frequency_students, student)
              daily_frequency_students = daily_frequency_students.where.not(id: frequencies_ids)
            end

            if daily_frequency_students.any?
              value = daily_frequency_students.absences.count
              absences[classroom.api_code][student.api_code][discipline.api_code]['valor'] = value
            end
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
      daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
      students_ids.flatten!.uniq! if students_ids.any?
      Student.find(students_ids)
    end

    def frequency_by_discipline?(classroom)
      FrequencyTypeDefiner.allow_frequency_by_discipline?(
        classroom,
        teacher
      )
    end

    def repeated_frequencies(daily_frequencies, classroom, discipline = nil)
      return if daily_frequencies.blank?
      return if classroom.period != Periods::FULL

      same_daily_frequencies_ids = []

      daily_frequencies.each do |daily_frequency1|
        daily_frequencies.each do |daily_frequency2|
          next if different_frequencies(daily_frequency1, daily_frequency2, same_daily_frequencies_ids, discipline)

          same_daily_frequencies_ids << [daily_frequency1.id, daily_frequency2.id]
        end
      end

      same_daily_frequencies_ids
    end

    def in_array?(element, array)
      array.select { |pair| pair.include?(element) }.any?
    end

    def different_frequencies(daily_frequency1, daily_frequency2, same_daily_frequencies_ids, discipline)
      return true if daily_frequency1 == daily_frequency2
      return true if in_array?(daily_frequency1.id, same_daily_frequencies_ids)
      return true if daily_frequency1.frequency_date != daily_frequency2.frequency_date
      return true if discipline && daily_frequency1.class_number != daily_frequency2.class_number

      false
    end

    def define_frequencies(daily_frequencies_ids, daily_frequency_students, student)
      return if daily_frequencies_ids.blank?

      frequencies_ids = []

      daily_frequencies_ids.each do |daily_frequency_id1, daily_frequency_id2|
        frequency1 = daily_frequency_students.find_by(
          daily_frequency_id: daily_frequency_id1,
          student_id: student.id
        )

        frequency2 = daily_frequency_students.find_by(
          daily_frequency_id: daily_frequency_id2,
          student_id: student.id
        )

        frequencies_ids << (frequency1.present ? frequency2.id : frequency1.id)
      end

      frequencies_ids
    end
  end
end
