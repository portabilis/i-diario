class StudentEnrollmentExemptedDisciplinesSynchronizer < BaseSynchronizer
  def synchronize!
    update_exempted_disciplines(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['dispensas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::StudentEnrollmentExemptedDisciplines
  end

  def update_exempted_disciplines(exempted_disciplines)
    changed_student_enrollment_exempted_disciplines = []

    exempted_disciplines.each do |exempted_discipline_record|
      student_enrollment = student_enrollment(exempted_discipline_record.matricula_id)
      discipline_id = discipline(exempted_discipline_record.disciplina_id).try(&:id)

      next if student_enrollment.blank? || discipline_id.blank?

      begin
        StudentEnrollmentExemptedDiscipline.with_discarded.find_or_initialize_by(
          student_enrollment_id: student_enrollment.id,
          discipline_id: discipline_id
        ).tap do |exempted_discipline|
          exempted_discipline.steps = exempted_discipline_record.etapas

          discard_exempted_discipline = exempted_discipline_record.deleted_at.present? ||
                                        exempted_discipline_record.etapas.blank?

          if exempted_discipline.changed?
            exempted_discipline.save!

            unless discard_exempted_discipline
              changed_student_enrollment_exempted_disciplines << [
                student_enrollment.id,
                discipline_id,
                exempted_discipline_record.etapas.split(',')
              ]
            end
          end

          exempted_discipline.discard_or_undiscard(discard_exempted_discipline)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end

    delete_dispensed_exams_and_frequencies(changed_student_enrollment_exempted_disciplines)
  end

  def delete_dispensed_exams_and_frequencies(changed_student_enrollment_exempted_disciplines)
    changed_student_enrollment_exempted_disciplines.uniq.each do |student_enrollment_id, discipline_id, steps|
      DeleteDispensedExamsAndFrequenciesWorker.perform_in(
        1.second,
        entity_id,
        student_enrollment_id,
        discipline_id,
        steps
      )
    end
  end
end
