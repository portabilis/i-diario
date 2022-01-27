class Select2GradeInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_classroom.present?
      classroom = options[:user].current_classroom

      input_html_options[:readonly] = 'readonly' unless classroom.multi_grade?
      input_html_options[:value] = classroom.grades.first.id unless classroom.multi_grade?
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    grades = []

    if user.current_classroom.present?
      grades = Grade.joins(classrooms_grades: :classroom)
                    .where(classrooms: { id: user.current_classroom })
    elsif user.current_teacher.present?
      grades = Grade.joins(classrooms_grades: :classroom)
                    .where(classrooms: { id: user.current_teacher.classrooms })
    elsif user.current_unity.present?
      grades = Grade.joins(classrooms_grades: :classroom)
                    .where(classrooms: { id: user.current_unity.classrooms })
    end

    options[:elements] = grades

    super
  end
end
