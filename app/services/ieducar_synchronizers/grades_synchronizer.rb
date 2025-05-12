class GradesSynchronizer < BaseSynchronizer
  def synchronize!
    update_grades(
      HashDecorator.new(
        api.fetch['series']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::Grades
  end

  def update_grades(grades)
    grades.each do |grade_record|
      course = course(grade_record.curso_id)

      next if course.blank?

      Grade.with_discarded.find_or_initialize_by(api_code: grade_record.id).tap do |grade|
        grade.description = grade_record.nome
        grade.course = course
        grade.save! if grade.changed?

        grade.discard_or_undiscard(grade_record.deleted_at.present?)
      end
    end
  end
end
