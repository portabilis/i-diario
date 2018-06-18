class Select2GradeInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_classroom.present?
      input_html_options[:readonly] = 'readonly'
      input_html_options[:value] = options[:user].current_classroom.grade.id
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    grades = []

    if user.current_classroom.present?
      grades = [ user.current_classroom.grade ]
    elsif user.current_teacher.present?
      grades = user.current_teacher.classrooms.map(&:grade).uniq
    elsif user.current_unity.present?
      grades = user.current_unity.classrooms.with_grade.map(&:grade).uniq
    end

    options[:elements] = grades

    super
  end
end
