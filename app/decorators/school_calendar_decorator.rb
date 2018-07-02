class SchoolCalendarDecorator
  include Decore
  include Decore::Proxy

  def self.current_steps_for_select2(school_calendar, classroom)
    steps = current_steps(school_calendar, classroom).map do |item|
      { id: item.id, name: item.to_s, text: item.to_s }
    end

    insert_empty_element(steps) if steps.any?

    steps.to_json
  end

  private

  def self.current_steps(school_calendar, classroom)
    if school_calendar_classroom = school_calendar.classrooms.find_by_classroom_id(classroom.id)
      school_calendar_classroom.classroom_steps
    else
      school_calendar.steps
    end
  end

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>', text: '' }
    elements.insert(0, empty_element)
  end
end
