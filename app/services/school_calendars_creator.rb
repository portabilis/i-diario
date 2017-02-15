class SchoolCalendarsCreator
  def self.create!(school_calendars)
    new(school_calendars).create!
  end

  def initialize(school_calendars)
    @school_calendars = school_calendars
  end

  def create!
    ActiveRecord::Base.transaction do
      selected_school_calendars_to_create.each do |school_calendar_params|
        school_calendar = SchoolCalendar.new(year: school_calendar_params['year'],
                                            unity_id: school_calendar_params['unity_id'],
                                            number_of_classes: school_calendar_params['number_of_classes'])

        school_calendar_params['steps'].each do |step_params|
          school_calendar.steps.build(start_at: step_params['start_at'],
                                      end_at: step_params['end_at'],
                                      start_date_for_posting: step_params['start_date_for_posting'],
                                      end_date_for_posting: step_params['end_date_for_posting'])
        end

        calendars_for_classrooms = school_calendar_params['classrooms'] || []
        calendars_for_classrooms.each do |classroom_params|
          school_calendar_classroom = SchoolCalendarClassroom.create!(
            school_calendar: school_calendar,
            classroom: Classroom.find_by_id(classroom_params['id'])
          )

          steps = []
          classroom_params['steps'].each do |step_params|
            steps << SchoolCalendarClassroomStep.create!(
              school_calendar_classroom: school_calendar_classroom,
              start_at: step_params['start_at'],
              end_at: step_params['end_at'],
              start_date_for_posting: step_params['start_date_for_posting'],
              end_date_for_posting: step_params['end_date_for_posting']
            )
          end
        end
      school_calendar.save!
      end
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_create
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].blank? }
  end
end
