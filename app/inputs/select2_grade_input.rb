class Select2GradeInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_classroom.present?
      grades = options[:user].current_classroom.grades
      multi_grades = grades.count > 1

      input_html_options[:readonly] = 'readonly' unless multi_grades
      input_html_options[:value] = grades.first.id unless multi_grades
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    grades = []

    if user.current_classroom.present?
      grades = user.current_classroom.grades
    elsif user.current_teacher.present?
      grades = user.current_teacher.classrooms.map(&:grades).uniq
    elsif user.current_unity.present?
      grades = user.current_unity.classrooms.with_grade.map(&:grades).uniq
    end

    options[:elements] = grades

    super
  end
end
