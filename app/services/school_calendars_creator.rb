class SchoolCalendarsCreator
  def self.create!(school_calendar)
    new(school_calendar).create!
  end

  def initialize(school_calendar)
    @school_calendar = school_calendar
  end

  def create!
    ActiveRecord::Base.transaction do
      if @school_calendar['school_calendar_id'].blank?
        begin
          school_calendar = create_school_calendar!(@school_calendar)
          school_calendar_steps = @school_calendar['steps'] || []
          create_school_calendar_steps!(school_calendar_steps, school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!("A validação falhou: ")

          raise SchoolCalendarSynchronizerService::InvalidSchoolCalendarError, I18n.t(
            '.school_calendars.create_and_update_batch.error_on_unity',
            unity_name: invalid.record.unity.name,
            error_message: message
          )
        end

        begin
          calendars_for_classrooms = @school_calendar['classrooms'] || []
          create_school_calendar_classroom!(calendars_for_classrooms, school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!("A validação falhou: ")

          raise SchoolCalendarSynchronizerService::InvalidClassroomCalendarError, I18n.t(
            '.school_calendars.create_and_update_batch.error_on_classroom',
            unity_name: invalid.record.classroom.unity.name,
            classroom_name: invalid.record.classroom.description,
            error_message: message
          )
        end

        @school_calendar
      end
    end
  end

  private

  def create_school_calendar!(school_calendar)
    school_calendar = SchoolCalendar.create!(
      year: school_calendar['year'],
      unity_id: school_calendar['unity_id'],
      number_of_classes: school_calendar['number_of_classes'],
      step_type_description: school_calendar['step_type_description']
    )

    school_calendar
  end

  def create_school_calendar_steps!(school_calendar_steps, school_calendar)
    school_calendar_steps.each do |step_params|
      SchoolCalendarStep.create!(
        school_calendar: school_calendar,
        step_number: step_params['step_number'],
        start_at: step_params['start_at'],
        end_at: step_params['end_at'],
        start_date_for_posting: step_params['start_date_for_posting'],
        end_date_for_posting: step_params['end_date_for_posting']
      )
    end
  end

  def create_school_calendar_classroom!(calendars_for_classrooms, school_calendar)
    calendars_for_classrooms.each do |classroom_params|
      school_calendar_classroom = SchoolCalendarClassroom.create!(
        school_calendar: school_calendar,
        step_type_description: classroom_params['step_type_description'],
        classroom_id: classroom_params['id'],
        classroom_api_code: classroom_params['classroom_api_code']
      )
      classroom_steps = classroom_params['steps'] || []
      create_school_calendar_classroom_steps!(classroom_steps, school_calendar_classroom)
    end
  end

  def create_school_calendar_classroom_steps!(classroom_steps, school_calendar_classroom)
    classroom_steps.each do |step_params|
      SchoolCalendarClassroomStep.create!(
        school_calendar_classroom: school_calendar_classroom,
        step_number: step_params['step_number'],
        start_at: step_params['start_at'],
        end_at: step_params['end_at'],
        start_date_for_posting: step_params['start_date_for_posting'],
        end_date_for_posting: step_params['end_date_for_posting']
      )
    end
  end
end
