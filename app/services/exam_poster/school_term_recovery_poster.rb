module ExamPoster
  class SchoolTermRecoveryPoster < Base
    def self.post!(post_data)
      new(post_data).post!
    end

    def post!
      post_by_classrooms.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            api.send_post(notas: { classroom_id => { student_id => { discipline_id => discipline_score } } }, etapa: @post_data.step.to_number, resource: 'recuperacoes')
          end
        end
      end
      return { warning_messages: "" }
    end

    def post_by_classrooms
      scores = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classroom_ids = teacher.teacher_discipline_classrooms.pluck(:classroom_id).uniq

      classroom_ids.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          classroom = teacher_discipline_classroom.classroom
          discipline = teacher_discipline_classroom.discipline

          next if !correct_score_type(classroom.exam_rule.score_type)
          next if !same_unity(classroom.unity_id)
          next unless step_exists_for_classroom?(classroom)

          teacher_score_fetcher = TeacherScoresFetcher.new(teacher, classroom, discipline, get_step(classroom))
          teacher_score_fetcher.fetch!

          student_scores = teacher_score_fetcher.scores

          student_scores.each do |student_score|
            next if exempted_discipline(classroom.id, discipline.id, student_score.id)

            school_term_recovery = fetch_school_term_recovery_score(classroom, discipline, student_score.id)
            if school_term_recovery
              value = StudentAverageCalculator.new(student_score).calculate(classroom, discipline, @post_data.step)
              scores[classroom.api_code][student_score.api_code][discipline.api_code]['nota'] = value
              scores[classroom.api_code][student_score.api_code][discipline.api_code]['recuperacao'] = ScoreRounder.new(classroom).round(school_term_recovery)
            end
          end

          students_only_with_recovery_fetcher = StudentOnlyWithRecoveryFetcher.new(teacher, classroom, discipline, @post_data.step)
          students_only_with_recovery_fetcher.fetch!
          students_without_daily_notes = students_only_with_recovery_fetcher.recoveries || []

          students_without_daily_notes.each do |student_recovery|
            student = student_recovery.student

            next if exempted_discipline(classroom.id, discipline.id, student.id)

            score = student_recovery.try(:score)
            if score
              scores[classroom.api_code][student.api_code][discipline.api_code]['recuperacao'] = ScoreRounder.new(classroom).round(score)
            end
          end

        end
      end
      return scores
    end

    private

    def api
      IeducarApi::PostRecoveries.new(@post_data.to_api)
    end

    def same_unity(unity_id)
      unity_id == @post_data.step.school_calendar.unity_id
    end

    def correct_score_type(score_type)
      score_type == ScoreTypes::NUMERIC
    end

    def fetch_school_term_recovery_score(classroom, discipline, student)
      if has_classroom_steps(classroom)
        school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord
          .by_classroom_id(classroom)
          .by_discipline_id(discipline)
          .by_school_calendar_classroom_step_id(get_step(classroom))
          .first
      else
        school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord
        .by_classroom_id(classroom)
        .by_discipline_id(discipline)
        .by_school_calendar_step_id(get_step(classroom))
        .first
      end

      return unless school_term_recovery_diary_record

      student_recovery = RecoveryDiaryRecordStudent
        .by_student_id(student)
        .by_recovery_diary_record_id(school_term_recovery_diary_record.recovery_diary_record_id)
        .first

      student_recovery.try(:score)
    end

    def exempted_discipline(classroom_id, discipline_id, student_id)
      student_enrollment_classroom = StudentEnrollmentClassroom.by_classroom(classroom_id)
                                                               .by_student(student_id)
                                                               .active
                                                               .first

      if student_enrollment_classroom.present?
        return student_enrollment_classroom.student_enrollment
                                           .exempted_disciplines
                                           .where("? = ANY(string_to_array(steps, ',')::integer[])", @post_data.step.to_number)
                                           .any?
      end

      false
    end
  end
end
