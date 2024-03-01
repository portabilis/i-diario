class CoursesSynchronizer < BaseSynchronizer
  def synchronize!
    update_courses(
      HashDecorator.new(
        api.fetch['cursos']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::Lectures
  end

  def update_courses(courses)
    courses.each do |course_record|
      Course.with_discarded.find_or_initialize_by(api_code: course_record.id).tap do |course|
        course.description = course_record.nome
        course.save! if course.changed?

        course.discard_or_undiscard(course_record.deleted_at.present?)
      end
    end
  end
end
