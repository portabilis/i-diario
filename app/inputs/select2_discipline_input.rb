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

    disciplines =
      if options[:record]&.persisted? && options[:record]&.discipline
        Discipline.where(id: options[:record].discipline.id)
      elsif options[:admin_or_employee].presence
        Discipline.by_classroom(user.current_classroom_id)
      elsif user.current_discipline_id?
        Discipline.where(id: user.current_discipline_id)
      elsif user.current_teacher.present? && options[:grade_id]
        Discipline.by_grade(options[:grade_id]).by_teacher_id(user.current_teacher.id, current_school_year)
      elsif user.current_teacher.present? && options[:classroom_id]
        Discipline.by_classroom(options[:classroom_id]).by_teacher_id(user.current_teacher.id, current_school_year)
      elsif user.current_unity.present? && options[:grade_id]
        Discipline.by_unity_id(user.current_unity.id, current_school_year).by_grade(options[:grade_id])
      end

    options[:elements] = disciplines.present? ? disciplines.grouped_by_knowledge_area : []

    super
  end

  private

  def input_value
    return options[:record].discipline_id if options[:record]&.persisted?

    options[:user].current_discipline.id unless options[:admin_or_employee].presence
  end
end
