class SchoolCalendarDecorator
  include Decore
  include Decore::Proxy

  def self.current_steps_for_select2_by_classrooms(school_calendar, classrooms)
    grouped_steps = current_steps_grouped_by_classroom(school_calendar, classrooms)

    if grouped_steps.size == 1
      # Quando há apenas uma turma, retorna sem agrupamento
      classroom = grouped_steps.keys.first
      steps = grouped_steps.values.first.map do |item|
        { id: "#{item.id}:#{classroom.id}", name: item.to_s, text: item.to_s }
      end
    else
      # Quando há múltiplas turmas, agrupa por turma
      steps = grouped_steps.map do |classroom, classroom_steps|
        {
          text: classroom.description,
          name: classroom.description,
          children: classroom_steps.map do |item|
            { id: "#{item.id}:#{classroom.id}", name: item.to_s, text: item.to_s }
          end
        }
      end
    end

    insert_empty_element(steps) if steps.any?

    steps.to_json
  end

  private

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>', text: '' }
    elements.insert(0, empty_element)
  end

  def self.current_steps_grouped_by_classroom(school_calendar, classrooms)
    classroom_ids = classrooms.map(&:id)

    school_calendar_classrooms = school_calendar.classrooms
                                                .includes(:classroom, :classroom_steps)
                                                .where(classroom_id: classroom_ids)

    classrooms_with_specific_calendar_ids = school_calendar_classrooms.map(&:classroom_id)

    general_steps = school_calendar.steps.to_a

    classrooms.each_with_object({}) do |classroom, grouped|
      if classrooms_with_specific_calendar_ids.include?(classroom.id)
        school_calendar_classroom = school_calendar_classrooms.find { |scc| scc.classroom_id == classroom.id }
        grouped[classroom] = school_calendar_classroom.classroom_steps.to_a
      else
        grouped[classroom] = general_steps
      end
    end
  end
end
