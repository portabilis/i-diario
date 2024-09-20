class DeleteDispensedExamsAndFrequenciesService
  def initialize(student_enrollment_id, discipline_id, steps)
    @student_enrollment_id = student_enrollment_id
    @discipline_id = discipline_id
    @steps = steps
  end

  def run!
    student_enrollment = StudentEnrollment.with_discarded.find(@student_enrollment_id)

    remove_dispensed_exams_and_frequencies(student_enrollment)
  end

  private

  def remove_dispensed_exams_and_frequencies(student_enrollment)
    student_enrollment.student_enrollment_classrooms.each do |student_enrollment_classroom|
      classroom = student_enrollment_classroom.classrooms_grade&.classroom

      next if classroom.blank?

      steps_fetcher = StepsFetcher.new(classroom)

      next if steps_fetcher.school_calendar.blank?

      @steps.each do |step_number|
        step = steps_fetcher.step(step_number)

        next if step.blank?

        start_date = step.start_at
        end_date = step.end_at
        student_id = student_enrollment.student_id
        classroom_id = classroom.id
        user_admin = User.find_by(admin: true)

        Audited.audit_class.as_user(user_admin) do
          destroy_invalid_daily_note_students(student_id, classroom_id, start_date, end_date)
          destroy_invalid_recovery_diary_record_students(student_id, classroom_id, start_date, end_date)
          destroy_invalid_conceptual_exams(student_id, classroom_id, step_number)
          destroy_invalid_descriptive_exams(student_id, classroom_id, step_number)
          destroy_invalid_daily_frequency_students(student_id, classroom_id, start_date, end_date)
        end
      end
    end
  end

  def destroy_invalid_daily_note_students(student_id, classroom_id, start_date, end_date)
    DailyNoteStudent.by_student_id(student_id)
                    .by_classroom_id(classroom_id)
                    .by_discipline_id(@discipline_id)
                    .by_test_date_between(start_date, end_date)
                    .destroy_all
  end

  def destroy_invalid_recovery_diary_record_students(student_id, classroom_id, start_date, end_date)
    recovery_diary_record_ids = RecoveryDiaryRecord.by_classroom_id(classroom_id)
                                                   .by_discipline_id(@discipline_id)
                                                   .by_recorded_at_between(start_date, end_date)

    RecoveryDiaryRecordStudent.by_student_id(student_id)
                              .by_recovery_diary_record_id(recovery_diary_record_ids)
                              .destroy_all
  end

  def destroy_invalid_conceptual_exams(student_id, classroom_id, step_number)
    conceptual_exam_ids = ConceptualExam.by_student_id(student_id)
                                        .by_classroom_id(classroom_id)
                                        .by_step_number(step_number)
                                        .pluck(:id)

    conceptual_exam_values = ConceptualExamValue.by_discipline_id(@discipline_id)
                                                .by_conceptual_exam_id(conceptual_exam_ids)

    conceptual_exam_values.each do |conceptual_exam_value|
      conceptual_exam_value.conceptual_exam.validation_type = :destroy
      conceptual_exam_value.destroy
    end
  end

  def destroy_invalid_descriptive_exams(student_id, classroom_id, step_number)
    descriptive_exam_ids = DescriptiveExam.by_discipline_id(@discipline_id)
                                          .by_classroom_id(classroom_id)
                                          .by_step_number(step_number)
                                          .pluck(:id)

    DescriptiveExamStudent.by_student_id(student_id)
                          .by_descriptive_exam_id(descriptive_exam_ids)
                          .destroy_all
  end

  def destroy_invalid_daily_frequency_students(student_id, classroom_id, start_date, end_date)
    DailyFrequencyStudent.by_student_id(student_id)
                         .by_classroom_id(classroom_id)
                         .by_discipline_id(@discipline_id)
                         .by_frequency_date_between(start_date, end_date)
                         .destroy_all
  end
end
