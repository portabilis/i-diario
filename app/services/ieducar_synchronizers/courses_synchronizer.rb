class CoursesSynchronizer < BaseSynchronizer
  def synchronize!
    update_courses(
      HashDecorator.new(
        api.fetch['cursos']
      )
    )
  end

  private

  def api_class
    IeducarApi::Lectures
  end

  def update_courses(courses)
    preload_courses(courses.map(&:id))

    courses.each do |course_record|
      (
        course(course_record.id) ||
        Course.new(api_code: course_record.id)
      ).tap do |course|
        course.description = course_record.nome
        course.save! if course.changed?

        course.discard_or_undiscard(course_record.deleted_at.present?)
      end
    end
  end
end
