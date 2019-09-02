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

      student = student(unification.main_id)

      next if student.blank?

      StudentUnification.find_or_initialize_by(
        student_id: student.id
      ).tap do |student_unification|
        student_unification.unified_at = unification.created_at
        student_unification.active = unification.active

        if student_unification.changed?
          new_record = student_unification.new_record?

          student_unification.save!

          secondary_students = []

          unification.duplicates_id.each do |api_code|
            secondary_students << student(api_code)
          end

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
    StudentUnificationService.new(main_student, secondary_students).run! if unify
    StudentUnificationReverterService.new(main_student, secondary_students).run! unless unify
  end
end
