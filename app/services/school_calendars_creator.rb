class SchoolCalendarsCreator
  class InvalidSchoolCalendarError < StandardError;end
  class InvalidClassroomCalendarError < StandardError; end
  def self.create!(school_calendars)
    new(school_calendars).create!
  end

  def initialize(school_calendars)
    @school_calendars = school_calendars
  end

  def create!
    ActiveRecord::Base.transaction do
      selected_school_calendars_to_create.each do |school_calendar_param|
        begin
          school_calendar = create_school_calendar!(school_calendar_param)
          school_calendar_steps = school_calendar_param['steps'] || []
          create_school_calendar_steps!(school_calendar_steps, school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!("A validação falhou: ")
          raise InvalidSchoolCalendarError, I18n.t('.school_calendars.create_and_update_batch.error_on_unity', unity_name: invalid.record.unity.name,
                                                                                                               error_message: message)
        end

        begin
          calendars_for_classrooms = school_calendar_param['classrooms'] || []
          create_school_calendar_classroom!(calendars_for_classrooms, school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!("A validação falhou: ")
          raise InvalidClassroomCalendarError, I18n.t('.school_calendars.create_and_update_batch.error_on_classroom', unity_name: invalid.record.classroom.unity.name,
                                                                                                                      classroom_name: invalid.record.classroom.description,
                                                                                                                      error_message: message)
        end
      end
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_create
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].blank? }
  end

  def create_school_calendar!(school_calendar_param)
    school_calendar = SchoolCalendar.create!(year: school_calendar_param['year'],
                                             unity_id: school_calendar_param['unity_id'],
                                             number_of_classes: school_calendar_param['number_of_classes'])
    school_calendar
  end

  def create_school_calendar_steps!(school_calendar_steps, school_calendar)
    school_calendar_steps.each do |step_params|
      SchoolCalendarStep.create!(school_calendar: school_calendar,
                                 start_at: step_params['start_at'],
                                 end_at: step_params['end_at'],
                                 start_date_for_posting: step_params['start_date_for_posting'],
                                 end_date_for_posting: step_params['end_date_for_posting'])
    end
  end

  def create_school_calendar_classroom!(calendars_for_classrooms, school_calendar)
    calendars_for_classrooms.each do |classroom_params|
      school_calendar_classroom = SchoolCalendarClassroom.create!(
        school_calendar: school_calendar,
        classroom: Classroom.find_by_id(classroom_params['id'])
      )
      classroom_steps = classroom_params['steps'] || []
      create_school_calendar_classroom_steps!(classroom_steps, school_calendar_classroom)
    end
  end

  def create_school_calendar_classroom_steps!(classroom_steps, school_calendar_classroom)
    classroom_steps.each do |step_params|
      SchoolCalendarClassroomStep.create!(
        school_calendar_classroom: school_calendar_classroom,
        start_at: step_params['start_at'],
        end_at: step_params['end_at'],
        start_date_for_posting: step_params['start_date_for_posting'],
        end_date_for_posting: step_params['end_date_for_posting']
      )
    end
  end
end
