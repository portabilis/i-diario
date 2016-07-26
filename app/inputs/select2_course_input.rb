class Select2CourseInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_classroom.present?
      input_html_options[:readonly] = 'readonly'
      input_html_options[:value] = options[:user].current_classroom.course.id
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    courses = []

    if user.current_classroom.present?
      courses = [ user.current_classroom.course ]
    elsif user.current_teacher.present?
      courses = user.current_teacher.classrooms.map(&:course).uniq
    elsif user.current_unity.present?
      courses = user.current_unity.classrooms.map(&:course).uniq
    end

    options[:elements] = courses

    super
  end
end
