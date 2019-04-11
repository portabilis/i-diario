class StudentEnrollmentExemptedDisciplinesSynchronizer < BaseSynchronizer
  def synchronize!
    update_exempted_disciplines(
      HashDecorator.new(
        api.fetch['dispensas']
      )
    )
  end

  private

  def api_class
    IeducarApi::StudentEnrollmentExemptedDisciplines
  end

  def update_exempted_disciplines(exempted_disciplines)
    ActiveRecord::Base.transaction do
      dispensed_discipline_ids_to_keep = []

      exempted_disciplines.each do |exempted_discipline_record|
        student_enrollment = student_enrollment(exempted_discipline_record.matricula_id)
        discipline_id = discipline(exempted_discipline_record.disciplina_id).try(&:id)

        next if student_enrollment.blank? || discipline_id.blank?

        StudentEnrollmentExemptedDiscipline.find_or_initialize_by(
          student_enrollment_id: student_enrollment.id,
          discipline_id: discipline_id
        ).tap do |exempted_discipline|
          exempted_discipline.steps = exempted_discipline_record.etapas
          exempted_discipline.save! if exempted_discipline.changed?

          dispensed_discipline_ids_to_keep << dispensed_disciplines.id
        end

        dispensed_discipline_ids_to_keep << dispensed_disciplines.id
        # remove_dispensed_exams_and_frequencies(
        #   student_enrollment,
        #   discipline_id,
        #   record['etapas'].split(',')
        # )
      end

      destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    end
  end

  def remove_dispensed_exams_and_frequencies(student_enrollment, discipline_id, steps)
    classroom = student_enrollment.student_enrollment_classrooms.first.classroom

    return if classroom.blank?

    steps_fetcher = StepsFetcher.new(classroom)

    return if school_calendar.school_calendar.blank?

    steps.each do |step_number|
      step = steps_fetcher.step(step_number)

      next if step.blank?

      start_date = step.start_at
      end_date = step.end_at

      DailyNoteStudent.by_student_id(student_enrollment.student_id)
                      .by_discipline_id(discipline_id)
                      .by_test_date_between(start_date, end_date)
                      .delete_all

      student_conceptual_exams = ConceptualExam.where(student_id: student_enrollment.student_id)
                                               .where(recorded_at: start_date..end_date)
                                               .pluck(:id)

      ConceptualExamValue.where(discipline_id: discipline_id)
                         .where(conceptual_exam_id: student_conceptual_exams)
                         .delete_all

      DailyFrequencyStudent.by_student_id(student_enrollment.student_id)
                           .by_discipline_id(discipline_id)
                           .by_frequency_date_between(start_date, end_date)
                           .delete_all
    end
  end

  def destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    StudentEnrollmentExemptedDiscipline.where.not(id: dispensed_discipline_ids_to_keep).destroy_all
  end
end
