class Select2ClassroomInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    if options[:user].current_classroom.present?
      input_html_options[:readonly] = 'readonly'
      input_html_options[:value] = if options[:record]&.persisted?
                                     options[:record].classroom_id
                                   else
                                     options[:user].current_classroom.id
                                   end
    end

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    classrooms = []

    if options[:record]&.persisted?
      classrooms = [options[:record].classroom]
    elsif user.current_classroom.present?
      classrooms = [ user.current_classroom ]
    elsif user.current_teacher.present?
      classrooms = user.current_teacher.classrooms
    elsif user.current_unity.present?
      classrooms = user.current_unity.classrooms
    end

    options[:elements] = classrooms

    super
  end
end
