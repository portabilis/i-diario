class StudentUnificationsSynchronizer < BaseSynchronizer
  def synchronize!
    update_student_unifications(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['unificacoes']
      )
    )
  end

  private

  def api_class
    IeducarApi::StudentUnifications
  end

  def update_student_unifications(unifications)
    unifications.each do |unification|
      next if unification.main_id.blank?

      student_id = Student.with_discarded.find_by(api_code: unification.main_id).try(:id)
      next if student_id.blank?

      StudentUnification.find_or_initialize_by(
        student_id: student_id
      ).tap do |student_unification|
        student_unification.unified_at = unification.created_at
        student_unification.active = unification.active

        new_record = false

        if student_unification.changed?
          new_record = true if student_unification.new_record?

          student_unification.save!

          if new_record
            unification.duplicates_id.each do |api_code|
              student_unification.unified_students.create!(
                student: Student.with_discarded.find_by(api_code: api_code)
              )
            end
          end

          next if !unification.active && new_record

          unify_or_revert(unification.active, student_id, unification.duplicates_id)
        end
      end
    end
  end

  def unify_or_revert(unify, student_id, duplicates_id)
    main_student = Student.with_discarded.find(student_id)
    secondary_students = Student.with_discarded.where(id: duplicates_id)

    if unify
      StudentUnificationService.new(main_student, secondary_students).run!
    else
      StudentUnificationReverterService.new(main_student, secondary_students).run!
    end
  end
end
