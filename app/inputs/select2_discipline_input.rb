class Select2DisciplineInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_discipline.present?
      input_html_options[:readonly] = 'readonly'
      input_html_options[:value] = options[:user].current_discipline.id
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    disciplines = []

    if user.current_discipline.present?
      disciplines = [ user.current_discipline ]
    elsif user.current_teacher.present? && options[:classroom_id]
      disciplines = Discipline.by_classroom(options[:classroom_id]).by_teacher_id(user.current_teacher.id)
    end

    options[:elements] = disciplines

    super
  end
end
