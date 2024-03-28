class StudentUnificationsSynchronizer < BaseSynchronizer
  def synchronize!
    update_student_unifications(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['unificacoes']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::StudentUnifications
  end

  def update_student_unifications(unifications)
    unifications.each do |unification|
      next if unification.main_id.blank?

      student = student(unification.main_id)

      next if student.blank?

      StudentUnification.find_or_initialize_by(
        api_code: unification.id
      ).tap do |student_unification|
        student_unification.unified_at = unification.created_at
        student_unification.active = unification.active
        student_unification.student_id = student.id

        if student_unification.changed?
          new_record = student_unification.new_record?

          student_unification.save!

          secondary_students = unification.duplicates_id.map { |api_code|
            student(api_code)
          }.compact

          if new_record
            secondary_students.each do |secondary_student|
              student_unification.unified_students.create!(
                student: secondary_student
              )
            end
          end

          next if !unification.active && new_record

          unify_or_revert(unification.active, student, secondary_students)
        end
      end
    end
  end

  def unify_or_revert(unify, main_student, secondary_students)
    if unify
      StudentUnification::UnificationService.new(main_student, secondary_students).run!
    else
      StudentUnification::ReverterService.new(main_student, secondary_students).run!
    end
  end
end
