class SchoolCalendarsParser
  def initialize(configuration)
    @configuration = configuration
  end

  def parse!
    school_calendars_from_api = api.fetch['escolas']
    build_school_calendars_to_synchronize(school_calendars_from_api)
  end

  def self.parse!(configuration)
    new(configuration).parse!
  end

  private

  attr_accessor :configuration

  def api
    IeducarApi::SchoolCalendars.new(configuration.to_api)
  end

  def build_school_calendars_to_synchronize(school_calendars_from_api)
    build_new_school_calendars(school_calendars_from_api) + build_existing_school_calendars(school_calendars_from_api)
  end

  def build_new_school_calendars(school_calendars_from_api)
    new_school_calendars_from_api = fetch_new_school_calendars_from_api(school_calendars_from_api)

    new_school_calendars_from_api.map do |school_calendar_from_api|
      unity = Unity.find_by(api_code: school_calendar_from_api['escola_id'])
      school_calendar = SchoolCalendar.new(
        unity: unity,
        year: school_calendar_from_api['ano'].to_i,
        number_of_classes: 4
      )

      school_calendar_from_api['etapas'].each do |step|
        school_calendar.steps.build(
          start_at: step['data_inicio'],
          end_at: step['data_fim'],
          start_date_for_posting: step['data_inicio'],
          end_date_for_posting: step['data_fim']
        )
      end

      steps_from_classrooms = get_school_calendar_classroom_steps(school_calendar_from_api['etapas_de_turmas'])
      steps_from_classrooms.each do |classroom_step|
        classroom = SchoolCalendarClassroom.new(
          classroom: Classroom.by_api_code(classroom_step['turma_id']).first
        )
        steps = []
        classroom_step['etapas'].each do |step|
          steps << SchoolCalendarClassroomStep.new(
            start_at: step['data_inicio'],
            end_at: step['data_fim'],
            start_date_for_posting: step['data_inicio'],
            end_date_for_posting: step['data_fim']
          )
        end

        school_calendar.classrooms.build(classroom.attributes).classroom_steps.build(steps.collect{ |step| step.attributes })
      end

      school_calendar
    end
  end

  def fetch_new_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).none?
    end
  end

  def build_existing_school_calendars(school_calendars_from_api)
    school_calendars_to_synchronize = []
    existing_school_calendars_from_api = fetch_existing_school_calendars_from_api(school_calendars_from_api)

    existing_school_calendars_from_api.each do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      unity = Unity.find_by(api_code: unity_api_code)
      school_calendar = SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).first

      school_calendar_from_api['etapas'].each_with_index do |step, index|
        if school_calendar.steps[index].present?
          update_step_start_at(school_calendar, index, step)
          update_step_end_at(school_calendar, index, step)
        else
          school_calendar.steps.build(
            start_at: step['data_inicio'],
            end_at: step['data_fim'],
            start_date_for_posting: step['data_inicio'],
            end_date_for_posting: step['data_fim']
          )
        end
      end

      steps_from_classrooms = get_school_calendar_classroom_steps(school_calendar_from_api['etapas_de_turmas'])
      steps_from_classrooms.each_with_index do |classroom_step, classroom_index|
        school_calendar_classroom = SchoolCalendarClassroom.by_classroom_api_code(classroom_step['turma_id']).first
        if school_calendar_classroom
          classroom_step['etapas'].each_with_index do |step, step_index|
            if school_calendar_classroom.classroom_steps[step_index]
              update_classrooms_step_start_at(school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }, step_index, step)
              update_classrooms_step_end_at(school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }, step_index, step)
            else
              step = SchoolCalendarClassroomStep.new(
                start_at: step['data_inicio'],
                end_at: step['data_fim'],
                start_date_for_posting: step['data_inicio'],
                end_date_for_posting: step['data_fim']
              )
              school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }.classroom_steps.build(step.attributes)
            end
          end
        else
          classroom = SchoolCalendarClassroom.new(
            classroom: Classroom.by_api_code(classroom_step['turma_id']).first
          )
          steps = []
          classroom_step['etapas'].each do |step|
            steps << SchoolCalendarClassroomStep.new(
              start_at: step['data_inicio'],
              end_at: step['data_fim'],
              start_date_for_posting: step['data_inicio'],
              end_date_for_posting: step['data_fim']
            )
          end

          school_calendar.classrooms.build(classroom.attributes).classroom_steps.build(steps.collect{ |step| step.attributes })
        end
      end

      need_to_synchronize = school_calendar_need_synchronization?(school_calendar) || school_calendar_classroom_step_need_synchronization?(school_calendar.classrooms)
      school_calendars_to_synchronize << school_calendar if need_to_synchronize
    end

    school_calendars_to_synchronize
  end

  def fetch_existing_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).any?
    end
  end

  def update_step_start_at(school_calendar, index, step)
    if school_calendar.steps[index].start_at != Date.parse(step['data_inicio'])
      school_calendar.steps[index].start_at = step['data_inicio']
      school_calendar.steps[index].start_date_for_posting = step['data_inicio']
    end
  end

  def update_step_end_at(school_calendar, index, step)
    if school_calendar.steps[index].end_at != Date.parse(step['data_fim'])
      school_calendar.steps[index].end_at = step['data_fim']
      school_calendar.steps[index].end_date_for_posting = step['data_fim']
    end
  end

  def update_classrooms_step_start_at(school_calendar_classroom, step_index, step)
    return unless school_calendar_classroom
    if school_calendar_classroom.classroom_steps[step_index].start_at != Date.parse(step['data_inicio'])
      school_calendar_classroom.classroom_steps[step_index].start_at = step['data_inicio']
      school_calendar_classroom.classroom_steps[step_index].start_date_for_posting = step['data_inicio']
    end
  end

  def update_classrooms_step_end_at(school_calendar_classroom, step_index, step)
    return unless school_calendar_classroom
    if school_calendar_classroom.classroom_steps[step_index].end_at != Date.parse(step['data_fim'])
      school_calendar_classroom.classroom_steps[step_index].end_at = step['data_fim']
      school_calendar_classroom.classroom_steps[step_index].end_date_for_posting = step['data_fim']
    end
  end

  def school_calendar_need_synchronization?(school_calendar)
    school_calendar.changed? || school_calendar.steps.any?(&:new_record?) || school_calendar.steps.any?(&:changed?) || school_calendar.classrooms.any?(&:new_record?)
  end

  def school_calendar_classroom_step_need_synchronization?(school_calendar_classroom)
    need = false
    school_calendar_classroom.each do |classroom|
      need = true if classroom.classroom_steps.any?(&:new_record?) || classroom.classroom_steps.any?(&:changed?)
    end
    need
  end

  private

  def get_school_calendar_classroom_steps(classroom_steps)
    classroom_steps.nil? ? [] : classroom_steps
  end
end
