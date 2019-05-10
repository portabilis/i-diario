module ExamPoster
  class NumericalExamPoster < Base
    SCORE_TYPES = [ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT].freeze
    DISCIPLINE_SCORE_TYPES = [DisciplineScoreTypes::NUMERIC, nil].freeze

    private

    def generate_requests
      for_each_postable_teacher_discipline_classroom do |teacher_discipline_classroom|
        for_each_student_with_calculable_average(teacher_discipline_classroom) do |student|
          student_average = calculate_student_average(teacher_discipline_classroom, student)
          recovery_score = calculate_recovery_score(teacher_discipline_classroom, student)
          requests << build_request(teacher_discipline_classroom, student, student_average, recovery_score)
        end
      end
    end

    def for_each_postable_teacher_discipline_classroom
      teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        yield(teacher_discipline_classroom) if can_post?(teacher_discipline_classroom.classroom)
      end
    end

    def teacher_discipline_classrooms
      teacher.teacher_discipline_classrooms
             .includes(:classroom)
             .by_score_type(DISCIPLINE_SCORE_TYPES)
    end

    def fetch_students(teacher_discipline_classroom)
      fetcher = TeacherScoresFetcher.new(
        teacher,
        teacher_discipline_classroom.classroom,
        teacher_discipline_classroom.discipline,
        get_step(teacher_discipline_classroom.classroom)
      )
      fetcher.fetch!
      @warning_messages += fetcher.warning_messages if fetcher.warnings?
      fetcher.scores
    end

    def for_each_student_with_calculable_average(teacher_discipline_classroom)
      students = fetch_students(teacher_discipline_classroom)
      students.each do |student|
        yield(student) unless skip_student_average_calculation?(teacher_discipline_classroom, student)
      end
    end

    def skip_student_average_calculation?(teacher_discipline_classroom, student_score)
      classroom, discipline = fetch_classroom_and_discipline(teacher_discipline_classroom)
      return true if exempted_discipline?(classroom, discipline, student_score)
      return true unless correct_score_type?(student_score, classroom)
      return true if exempted_discipline_in_step?(classroom, discipline)
    end

    def calculate_student_average(teacher_discipline_classroom, student)
      classroom, discipline = fetch_classroom_and_discipline(teacher_discipline_classroom)
      StudentAverageCalculator.new(student).calculate(classroom, discipline, get_step(classroom))
    end

    def calculate_recovery_score(teacher_discipline_classroom, student)
      classroom, discipline = fetch_classroom_and_discipline(teacher_discipline_classroom)

      school_term_recovery = school_term_recovery_diary_record(classroom, discipline)
      return if school_term_recovery.nil?

      score = recovery_diary_record_student_score(school_term_recovery, student)
      return if score.nil?

      score = complementary_exam_calculator(classroom, discipline, student).calculate(score)
      ScoreRounder.new(classroom, RoundedAvaliations::SCHOOL_TERM_RECOVERY).round(score)
    end

    def build_request(teacher_discipline_classroom, student, student_average, recovery_score = nil)
      classroom, discipline = fetch_classroom_and_discipline(teacher_discipline_classroom)
      student_scores = { 'nota' => student_average }
      student_scores['recuperacao'] = recovery_score if recovery_score.present?
      {
        info: {
          classroom: classroom.api_code,
          student: student.api_code,
          discipline: discipline.api_code
        },
        request: {
          etapa: @post_data.step.to_number,
          resource: 'notas',
          notas: {
            classroom.api_code => {
              student.api_code => {
                discipline.api_code => student_scores
              }
            }
          }
        }
      }
    end

    def exempted_discipline?(classroom, discipline, student_score)
      student_enrollment_classroom = StudentEnrollmentClassroom.by_classroom(classroom.id)
                                                               .by_student(student_score.id)
                                                               .active
                                                               .first
      return if student_enrollment_classroom.nil?

      student_enrollment_classroom.student_enrollment
                                  .exempted_disciplines
                                  .by_discipline(discipline)
                                  .by_step_number(get_step(classroom).to_number)
                                  .any?
    end

    def correct_score_type?(student_score, classroom)
      exam_rule = student_score.uses_differentiated_exam_rule || classroom.exam_rule
      SCORE_TYPES.include?(exam_rule.score_type)
    end

    def exempted_discipline_in_step?(classroom, discipline)
      ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)
      ids.include?(discipline.id)
    end

    def school_term_recovery_diary_record(classroom, discipline)
      SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom)
                                   .by_discipline_id(discipline)
                                   .by_step_id(classroom, get_step(classroom).id)
                                   .first
    end

    def recovery_diary_record_student_score(school_term_recovery_diary_record, student)
      recovery_diary_record_id = school_term_recovery_diary_record.recovery_diary_record_id
      RecoveryDiaryRecordStudent.by_student_id(student)
                                .by_recovery_diary_record_id(recovery_diary_record_id)
                                .first
                                .try(:score)
    end

    def complementary_exam_calculator(classroom, discipline, student)
      ComplementaryExamCalculator.new(
        AffectedScoreTypes::STEP_RECOVERY_SCORE,
        student,
        discipline.id,
        classroom.id,
        get_step(classroom)
      )
    end

    def fetch_classroom_and_discipline(teacher_discipline_classroom)
      [teacher_discipline_classroom.classroom, teacher_discipline_classroom.discipline]
    end
  end
end
