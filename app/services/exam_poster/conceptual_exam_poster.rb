module ExamPoster
  class ConceptualExamPoster < Base
    private

    def generate_requests
      post_conceptual_exams.each do |classroom_id, conceptual_exam_classroom|
        conceptual_exam_classroom.each do |student_id, conceptual_exam_student|
          conceptual_exam_student.each do |discipline_id, conceptual_exam_discipline|
            requests << {
              info: {
                classroom: classroom_id,
                student: student_id,
                discipline: discipline_id
              },
              request: {
                etapa: @post_data.step.to_number,
                resource: 'notas',
                notas: {
                  classroom_id => {
                    student_id => {
                      discipline_id => conceptual_exam_discipline
                    }
                  }
                }
              }
            }
          end
        end
      end
    end

    def post_conceptual_exams
      params = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classrooms.each do |classroom|
        next unless can_post?(classroom)
        step = get_step(classroom)
        conceptual_exams = ConceptualExam.joins(:student)
                                         .by_classroom(classroom)
                                         .by_unity(step.school_calendar.unity)
                                         .by_step_id(classroom, step.id)

        students = conceptual_exams.map(&:student_id)
        exempted_disciplines = exempt_discipline_students(classroom, discipline_ids, students, step.to_number)
        exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, step.to_number)
        conceptual_exam_values = ConceptualExamValue.active
                                                    .includes(:conceptual_exam, :discipline)
                                                    .where(conceptual_exam_id: conceptual_exams.pluck(:id))
                                                    .where.not(discipline_id: exempted_discipline_ids)
                                                    .where(discipline_id: discipline_ids)
                                                    .distinct

        conceptual_exam_values.each do |conceptual_exam_value|
          conceptual_exam = conceptual_exam_value.conceptual_exam
          next if exempted_disciplines[conceptual_exam.student_id].present?
          next unless not_posted?({ classroom: classroom, student: conceptual_exam.student, discipline: conceptual_exam_value.discipline })[:conceptual_exam]

          if conceptual_exam_value.value.blank?
            student_name = conceptual_exam.student.name
            classroom_description = conceptual_exam.classroom.description
            discipline_description = conceptual_exam_value.discipline.description
            @warning_messages << "O aluno #{student_name} não possui nota lançada no diário de notas conceituais na turma #{classroom_description} disciplina: #{discipline_description}"
            next
          end

          classroom_api_code = conceptual_exam.classroom.api_code
          student_api_code = conceptual_exam.student.api_code
          discipline_api_code = conceptual_exam_value.discipline.api_code

          params[classroom_api_code][student_api_code][discipline_api_code]['nota'] = conceptual_exam_value.value
        end
      end

      params
    end

    def exempt_discipline_students(classroom, discipline_ids, student_ids, step_number)
      student_enrollments = StudentEnrollmentClassroom.includes(student_enrollment: [:student])
                                                      .by_classroom(classroom.id)
                                                      .by_student(student_ids)
                                                      .active
                                                      .map(&:student_enrollment)

      exempt_discipline_students = StudentEnrollmentExemptedDiscipline.includes(student_enrollment: :student)
                                                                      .where(
                                                                        student_enrollment: student_enrollments,
                                                                        discipline_id: discipline_ids
                                                                      )
                                                                      .by_step_number(step_number)

      return {} if exempt_discipline_students.blank?

      student_exempted_in_disciplines = {}

      exempt_discipline_students.each do |exempt|
        student_id = exempt.student_enrollment.student_id

        next if student_exempted_in_disciplines.key?(student_id)

        student_exempted_in_disciplines[student_id] = exempt
      end

      student_exempted_in_disciplines
    end
  end
end
