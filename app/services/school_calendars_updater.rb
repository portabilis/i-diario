class SchoolCalendarsUpdater
  class InvalidSchoolCalendarError < StandardError;end
  class InvalidClassroomCalendarError < StandardError;end

  def self.update!(school_calendar)
    new(school_calendar).update!
  end

  def initialize(school_calendar)
    @school_calendar = school_calendar
  end

  def update!
    ActiveRecord::Base.transaction do
      if @school_calendar['school_calendar_id'].present?
        school_calendar = SchoolCalendar.find_by_id(@school_calendar['school_calendar_id'])

        begin
          update_school_calendar_steps(school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!('A validação falhou: ')

          raise InvalidSchoolCalendarError, I18n.t(
            '.school_calendars.create_and_update_batch.error_on_unity',
            unity_name: invalid.record.unity.name,
            error_message: message
          )
        end

        begin
          update_school_calendar_classroom_steps(school_calendar)
        rescue ActiveRecord::RecordInvalid => invalid
          message = invalid.to_s
          message.slice!('A validação falhou: ')

          raise InvalidClassroomCalendarError, I18n.t(
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

  def update_school_calendar_steps(school_calendar)
    school_calendar_steps_ids_marked_for_destruction = []

    (@school_calendar['steps'] || []).each_with_index do |step_params, index|
      school_calendar_step = school_calendar.steps[index]

      if school_calendar_step.present?
        school_calendar_steps_ids_marked_for_destruction << school_calendar_step.id if step_params['_destroy'] == 'true'

        update_school_calendar_step!(school_calendar, step_params, index)
      else
        create_school_calendar_step!(school_calendar, step_params)
      end
    end

    destroy_school_calendar_steps_marked_for_destruction(school_calendar, school_calendar_steps_ids_marked_for_destruction)
  end

  def update_school_calendar_classroom_steps(school_calendar)
    school_calendar_classroom_ids_marked_for_destruction = []
    school_calendar_classroom_steps_ids_marked_for_destruction = []

    (@school_calendar['classrooms'] || []).each_with_index do |classroom_params, classroom_index|
      school_calendar_classroom = SchoolCalendarClassroom.by_classroom_id(classroom_params['id']).first

      if school_calendar_classroom.present?
        school_calendar_classroom_ids_marked_for_destruction << school_calendar_classroom.id if classroom_params['_destroy'] == 'true'

        (classroom_params['steps'] || []).each_with_index do |step_params, step_index|
          school_calendar_classroom_step = school_calendar_classroom.classroom_steps[step_index]

          if school_calendar_classroom_step.present?
            school_calendar_classroom_steps_ids_marked_for_destruction << school_calendar_classroom_step.id if step_params['_destroy'] == 'true'

            update_school_calendar_classroom_step!(school_calendar_classroom, step_index, step_params)
          else
            create_school_calendar_classroom_step!(school_calendar_classroom, step_params)
          end
        end
      else
        school_calendar_classroom = create_school_calendar_classroom!(classroom_params, school_calendar)

        (classroom_params['steps'] || []).each do |step_params|
          create_school_calendar_classroom_step!(school_calendar_classroom, step_params)
        end
      end

      destroy_classroom_steps_marked_for_destruction(school_calendar_classroom, school_calendar_classroom_steps_ids_marked_for_destruction)
    end

    destroy_school_calendar_classrooms_marked_for_destruction(school_calendar, school_calendar_classroom_ids_marked_for_destruction)
  end

  def update_school_calendar_classroom_step!(school_calendar_classroom, step_index, step_params)
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

  def create_school_calendar_classroom!(classroom_params, school_calendar)
    school_calendar_classroom = SchoolCalendarClassroom.create!(
      school_calendar: school_calendar,
      classroom: Classroom.find_by_id(classroom_params['id'])
    )
  end

  def create_school_calendar_classroom_step!(school_calendar_classroom, step_params)
    SchoolCalendarClassroomStep.create!(
      school_calendar_classroom: school_calendar_classroom,
      start_at: step_params['start_at'],
      end_at: step_params['end_at'],
      start_date_for_posting: step_params['start_date_for_posting'],
      end_date_for_posting: step_params['end_date_for_posting']
    )
  end

  def create_school_calendar_step!(school_calendar, step_params)
    SchoolCalendarStep.create!(
      school_calendar: school_calendar,
      start_at: step_params['start_at'],
      end_at: step_params['end_at'],
      start_date_for_posting: step_params['start_date_for_posting'],
      end_date_for_posting: step_params['end_date_for_posting']
    )
  end

  def destroy_school_calendar_steps_marked_for_destruction(school_calendar, school_calendar_steps_ids_marked_for_destruction)
    school_calendar.steps.where(id: school_calendar_steps_ids_marked_for_destruction).destroy_all
  end

  def destroy_classroom_steps_marked_for_destruction(school_calendar_classroom, school_calendar_classroom_steps_ids_marked_for_destruction)
    school_calendar_classroom.classroom_steps.where(id: school_calendar_classroom_steps_ids_marked_for_destruction).destroy_all
  end

  def destroy_school_calendar_classrooms_marked_for_destruction(school_calendar, school_calendar_classroom_ids_marked_for_destruction)
    school_calendar.classrooms.where(id: school_calendar_classroom_ids_marked_for_destruction).destroy_all
  end
end
