class SchoolCalendarsUpdater
  class InvalidSchoolCalendarError < StandardError;end
  class InvalidClassroomCalendarError < StandardError; end
  def self.update!(school_calendars)
    new(school_calendars).update!
  end

  def initialize(school_calendars)
    @school_calendars = school_calendars
  end

  def update!
    ActiveRecord::Base.transaction do
      selected_school_calendars_to_update.each do |school_calendar_params|

        school_calendar = SchoolCalendar.find_by(id: school_calendar_params['school_calendar_id'])

        begin
          school_calendar_params['steps'].each_with_index do |step_params, index|
            if school_calendar.steps[index].present?
              update_school_calendar_step!(school_calendar, step_params, index)
            else
              create_school_calendar_step!(school_calendar, step_params)
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          raise InvalidSchoolCalendarError, I18n.t('.school_calendars.create_and_update_batch.error_on_unity', unity_name: invalid.record.unity.name)
        end


        begin
          school_calendar_params['classrooms'].each_with_index do |classroom_params, classroom_index|
            school_calendar_classroom = SchoolCalendarClassroom.by_classroom_id(classroom_params['id']).first

            if school_calendar_classroom
              classroom_params['steps'].each_with_index do |step_params, step_index|
                if school_calendar_classroom.classroom_steps[step_index]
                  update_school_calendar_classroom_steps!(school_calendar_classroom, step_index, step_params)
                else
                  create_school_calendar_classroom_steps!(school_calendar_classroom, step_params)
                end
              end
            else

              school_calendar_classroom = create_school_calendar_classroom!(classroom_params)
              classroom_params['steps'].each do |step_params|
                create_school_calendar_classroom_steps!(school_calendar_classroom, step_params)
              end
            end
          end

        rescue ActiveRecord::RecordInvalid => invalid
          raise InvalidClassroomCalendarError, I18n.t('.school_calendars.create_and_update_batch.error_on_classroom', unity_name: invalid.record.classroom.unity.name, classroom_name: invalid.record.classroom.description)
        end
      end
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_update
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].present? }
  end

  def update_school_calendar_classroom_steps!(school_calendar_classroom, step_index, step_params)
    school_calendar_classroom.classroom_steps[step_index].start_at = step_params['start_at']
    school_calendar_classroom.classroom_steps[step_index].start_date_for_posting = step_params['start_date_for_posting']
    school_calendar_classroom.classroom_steps[step_index].end_at = step_params['end_at']
    school_calendar_classroom.classroom_steps[step_index].end_date_for_posting = step_params['end_date_for_posting']
    school_calendar_classroom.classroom_steps[step_index].save!
  end

  def update_school_calendar_step!(school_calendar, step_params, index)
    school_calendar.steps[index].start_at = step_params['start_at']
    school_calendar.steps[index].start_date_for_posting = step_params['start_date_for_posting']
    school_calendar.steps[index].end_at = step_params['end_at']
    school_calendar.steps[index].end_date_for_posting = step_params['end_date_for_posting']
    school_calendar.steps[index].save!
  end

  def create_school_calendar!(school_calendar, step_params)
    SchoolCalendarStep.create!(
      school_calendar: school_calendar,
      start_at: step_params['start_at'],
      end_at: step_params['end_at'],
      start_date_for_posting: step_params['start_date_for_posting'],
      end_date_for_posting: step_params['end_date_for_posting']
    )
  end

  def create_school_calendar_classroom!(classroom_params)
    school_calendar_classroom = SchoolCalendarClassroom.create!(
      classroom: Classroom.find_by_id(classroom_params['id'])
    )
  end

  def create_school_calendar_classroom_steps!(school_calendar_classroom, step_params)
    SchoolCalendarClassroomStep.create!(
      school_calendar_classroom: school_calendar_classroom,
      start_at: step_params['start_at'],
      end_at: step_params['end_at'],
      start_date_for_posting: step_params['start_date_for_posting'],
      end_date_for_posting: step_params['end_date_for_posting']
    )
  end
end
