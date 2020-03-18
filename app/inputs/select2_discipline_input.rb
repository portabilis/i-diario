class Select2DisciplineInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_discipline.present?
      input_html_options[:readonly] = 'readonly' unless options[:admin_or_employee].presence
      input_html_options[:value] = input_value if input_html_options[:value].blank?
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    disciplines = []

    if options[:record]&.persisted?
      disciplines = [options[:record].discipline]
    elsif options[:admin_or_employee].presence
      disciplines = Discipline.by_classroom(user.current_classroom_id)
    elsif user.current_discipline.present?
      disciplines = [ user.current_discipline ]
    elsif user.current_teacher.present? && options[:grade_id]
      disciplines = Discipline.by_grade(options[:grade_id]).by_teacher_id(user.current_teacher.id)
    elsif user.current_teacher.present? && options[:classroom_id]
      disciplines = Discipline.by_classroom(options[:classroom_id]).by_teacher_id(user.current_teacher.id)
    elsif user.current_unity.present? && options[:grade_id]
      disciplines = Discipline.by_unity_id(user.current_unity.id).by_grade(options[:grade_id])
    end

    options[:elements] = disciplines

    super
  end

  private

  def input_value
    return options[:record].discipline_id if options[:record]&.persisted?

    options[:user].current_discipline.id unless options[:admin_or_employee].presence
  end
end
