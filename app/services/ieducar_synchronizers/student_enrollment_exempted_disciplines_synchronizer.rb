class StudentEnrollmentExemptedDisciplinesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['dispensas']
  end

  protected

  def api
    IeducarApi::StudentEnrollmentExemptedDisciplines.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      dispensed_discipline_ids_to_keep = []

      collection.each do |record|
        student_enrollment = StudentEnrollment.find_by(api_code: record['matricula_id'])
        student_enrollment_id = student_enrollment.try(&:id)
        discipline_id = Discipline.find_by(api_code: record['disciplina_id']).try(&:id)

        next unless student_enrollment_id.present? && discipline_id.present?

        dispensed_disciplines = StudentEnrollmentExemptedDiscipline.find_or_create_by(
          student_enrollment_id: student_enrollment_id,
          discipline_id: discipline_id
        )
        dispensed_disciplines.update_attribute(:steps, record['etapas'])

        dispensed_discipline_ids_to_keep << dispensed_disciplines.id
        remove_dispensed_exams_and_frequencies(
          student_enrollment,
          discipline_id,
          record['etapas'].split(',')
        )
      end

      destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    end
  end

  def remove_dispensed_exams_and_frequencies(student_enrollment, discipline_id, steps)
    classroom = student_enrollment.student_enrollment_classrooms.first.classroom

    return if classroom.blank?

    school_calendar = CurrentSchoolCalendarFetcher.new(classroom.unity, classroom).fetch

    return if school_calendar.blank?

    steps.each do |step_number|
      step = school_calendar.steps.ordered.find { |school_calendar_step|
        school_calendar_step.to_number == step_number.to_i
      }

      next unless step

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
