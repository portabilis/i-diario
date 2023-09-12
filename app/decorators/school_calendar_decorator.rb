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

  def self.current_steps_for_select2_by_classrooms(school_calendar, classrooms)
    steps = current_steps_by_classrooms(school_calendar, classrooms).map do |item|
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

  def self.current_steps_by_classrooms(school_calendar, classrooms)
    classroom_ids = classrooms.map(&:id)
    school_calendar_classroom = school_calendar.classrooms.where(classroom_id: classroom_ids)

    if school_calendar_classroom.present?
      school_calendar_classroom.map(&:classroom_steps).flatten
    else
      school_calendar.steps
    end
  end

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>', text: '' }
    elements.insert(0, empty_element)
  end
end
