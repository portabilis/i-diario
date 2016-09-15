class SchoolCalendarsUpdater
  def self.update!(school_calendars)
    new(school_calendars).update!
  end

  def initialize(school_calendars)
    self.school_calendars = school_calendars
  end

  def update!
    selected_school_calendars_to_update.each do |school_calendar_params|
      school_calendar = SchoolCalendar.find_by(id: school_calendar_params['school_calendar_id'])

      school_calendar_params['steps'].each_with_index do |step_params, index|
        if school_calendar.steps[index].present?
          school_calendar.steps[index].start_at = step_params['start_at']
          school_calendar.steps[index].start_date_for_posting = step_params['start_date_for_posting']
          school_calendar.steps[index].end_at = step_params['end_at']
          school_calendar.steps[index].end_date_for_posting = step_params['end_date_for_posting']
        else
          school_calendar.steps.build(
            start_at: step_params['start_at'],
            end_at: step_params['end_at'],
            start_date_for_posting: step_params['start_date_for_posting'],
            end_date_for_posting: step_params['end_date_for_posting']
          )
        end
      end

      school_calendar_params['classrooms'].each_with_index do |classroom_params, classroom_index|
        if school_calendar.classrooms[classroom_index].present?
          classroom_params['steps'].each_with_index do |step_params, step_index|
            school_calendar.classrooms[classroom_index].classroom_steps[step_index].start_at = step_params['start_at']
            school_calendar.classrooms[classroom_index].classroom_steps[step_index].start_date_for_posting = step_params['start_date_for_posting']
            school_calendar.classrooms[classroom_index].classroom_steps[step_index].end_at = step_params['end_at']
            school_calendar.classrooms[classroom_index].classroom_steps[step_index].end_date_for_posting = step_params['end_date_for_posting']
          end
        else
          classroom = SchoolCalendarClassroom.new(
            classroom: Classroom.find_by_id(classroom_params['id'])
          )

          steps = []
          classroom_params['steps'].each_with_index do |step_params, index|
            steps << SchoolCalendarClassroomStep.new(
              start_at: step_params['start_at'],
              end_at: step_params['end_at'],
              start_date_for_posting: step_params['start_date_for_posting'],
              end_date_for_posting: step_params['end_date_for_posting']
            )
          end

          school_calendar.classrooms.build(classroom.attributes).classroom_steps.build(steps.collect{ |step| step.attributes })
        end
      end

      school_calendar.save!
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_update
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].present? }
  end
end
