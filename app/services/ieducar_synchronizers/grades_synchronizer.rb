class GradesSynchronizer < BaseSynchronizer
  def synchronize!
    update_grades(
      HashDecorator.new(
        api.fetch(
          escola_id: unity_api_code
        )['series']
      )
    )
  end

  def self.synchronize_in_batch!(params)
    params[:filtered_by_unity] = true

    super
  end

  private

  def api_class
    IeducarApi::Grades
  end

  def update_grades(grades)
    grades.each do |grade_record|
      next if grade_record.curso_id.blank?

      Grade.with_discarded.find_or_initialize_by(api_code: grade_record.id).tap do |grade|
        grade.description = grade_record.nome
        grade.course = course(grade_record.curso_id)
        grade.save! if grade.changed?

        grade.discard_or_undiscard(grade_record.deleted_at.present?)
      end
    end
  end
end
