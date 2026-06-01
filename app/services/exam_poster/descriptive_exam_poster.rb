module ExamPoster
  class DescriptiveExamPoster < Base
    private

    def generate_requests
      post_by_step.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          requests << {
            info: {
              classroom: classroom_id,
              student: student_id
            },
            request: {
              etapa: @post_data.step.to_number,
              resource: 'pareceres-por-etapa-geral',
              pareceres: {
                classroom_id => {
                  student_id => descriptive_exam
                }
              }
            }
          }
        end
      end

      post_by_year.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          requests << {
            info: {
              classroom: classroom_id,
              student: student_id
            },
            request: {
              resource: 'pareceres-anual-geral',
              pareceres: {
                classroom_id => {
                  student_id => descriptive_exam
                }
              }
            }
          }
        end
      end

      post_by_year_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            requests << {
              info: {
                classroom: classroom_id,
                student: student_id,
                discipline: discipline_id
              },
              request: {
                resource: 'pareceres-anual-por-componente',
                pareceres: {
                  classroom_id => {
                    student_id => {
                      discipline_id => discipline_descriptive_exam
                    }
                  }
                }
              }
            }
          end
        end
      end

      post_by_step_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            requests << {
              info: {
                classroom: classroom_id,
                student: student_id,
                discipline: discipline_id
              },
              request: {
                etapa: @post_data.step.to_number,
                resource: 'pareceres-por-etapa-e-componente',
                pareceres: {
                  classroom_id => {
                    student_id => {
                      discipline_id => discipline_descriptive_exam
                    }
                  }
                }
              }
            }
          end
        end
      end
    end

    def post_by_step
      descriptive_exams = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next unless can_post?(classroom)

        exams = DescriptiveExamStudent.joins(:descriptive_exam)
                                      .joins(:student)
                                      .includes(:student, :descriptive_exam)
                                      .by_classroom_and_discipline(classroom, nil)
                                      .merge(
                                        DescriptiveExam.by_step_id(classroom, get_step(classroom).id)
                                      )
                                      .ordered

        exams.each do |exam|
          next if exam.student.nil?
          next unless not_posted?({ classroom: classroom, student: exam.student })[:descriptive_exam]
          next unless valid_opinion_type?(
            exam.student.uses_differentiated_exam_rule,
            OpinionTypes::BY_STEP, classroom
          )

          descriptive_exams[classroom.api_code][exam.student.api_code]['valor'] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year
      descriptive_exams = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classrooms.each do |classroom|
        next unless can_post?(classroom)

        exams = DescriptiveExamStudent.by_classroom_and_discipline(classroom, nil)
                                      .ordered

        exams.each do |exam|
          next if exam.student.nil?
          next unless not_posted?({ classroom: classroom, student: exam.student })[:descriptive_exam]
          next unless valid_opinion_type?(
            exam.student.uses_differentiated_exam_rule,
            OpinionTypes::BY_YEAR, classroom
          )

          descriptive_exams[classroom.api_code][exam.student.api_code]['valor'] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year_and_discipline
      descriptive_exams = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next unless can_post?(classroom)

        exempted_discipline_ids =
          ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)

        next if exempted_discipline_ids.include?(discipline.id)

        exams = DescriptiveExamStudent.joins(:student).by_classroom_and_discipline(classroom, discipline).ordered
        exams.each do |exam|
          next if exam.student.nil?
          next unless not_posted?({ classroom: classroom, discipline: discipline, student: exam.student })[:descriptive_exam]
          next unless valid_opinion_type?(
            exam.student.try(:uses_differentiated_exam_rule),
            OpinionTypes::BY_YEAR_AND_DISCIPLINE,
            classroom
          )

          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]['valor'] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_step_and_discipline
      descriptive_exams = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next unless can_post?(classroom)

        exempted_discipline_ids =
          ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)

        next if exempted_discipline_ids.include?(discipline.id)

        exams = DescriptiveExamStudent.joins(:descriptive_exam)
                                      .includes(:student, :descriptive_exam)
                                      .merge(
                                        DescriptiveExam.by_classroom_id(classroom.id)
                                                       .by_discipline_id(discipline.id)
                                                       .by_step_id(classroom, get_step(classroom).id)
                                      )
                                      .ordered

        exams.each do |exam|
          next if exam.student.nil?
          next unless not_posted?({ classroom: classroom, discipline: discipline, student: exam.student })[:descriptive_exam]
          next unless valid_opinion_type?(
            exam.student.try(:uses_differentiated_exam_rule),
            OpinionTypes::BY_STEP_AND_DISCIPLINE,
            classroom
          )

          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]['valor'] = exam.value
        end
      end

      descriptive_exams
    end

    # Em turmas multisseriadas cada série tem seu próprio exam_rule (um por
    # classrooms_grade), e podem ter opinion_types diferentes (ex.: 1º ano usa
    # parecer descritivo e 2º ano não). Por isso precisamos validar contra todas
    # as regras da turma, e não apenas contra a primeira (classrooms_grades.first),
    # cuja ordem depende apenas de qual série foi vinculada primeiro.
    def valid_opinion_type?(differentiated, opinion_type, classroom)
      exam_rules_for(classroom).any? do |exam_rule|
        exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if differentiated
        exam_rule.opinion_type == opinion_type
      end
    end

    def exam_rules_for(classroom)
      @exam_rules_for ||= {}
      @exam_rules_for[classroom.id] ||= classroom.classrooms_grades.map(&:exam_rule).compact
    end
  end
end
