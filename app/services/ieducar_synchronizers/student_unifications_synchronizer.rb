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

      StudentUnification.find_or_initialize_by(
        student_id: Student.find_by(api_code: unification.main_id).try(:id)
      ).tap do |student_unification|
        student_unification.unified_at = unification.created_at
        student_unification.active = unification.active

        if student_unification.changed?
          student_unification.save!

          unification.duplicates_id.each do |id|
            student_unification.unified_students.create!(
              student: Student.with_discarded.find_by(api_code: id)
            )
          end
        end
      end
    end
  end
end
