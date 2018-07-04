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

        update_school_calendar_steps(school_calendar)
        update_school_calendar_classroom_steps(school_calendar)

        @school_calendar
      end
    end
  end

  private

  attr_accessor :school_calendars

  def update_school_calendar_steps(school_calendar)
    @school_calendar_steps = {}
    school_calendar_steps_ids_marked_for_destruction = []

    (@school_calendar['steps'] || []).each_with_index do |step_params, index|
      school_calendar_step = school_calendar.steps[index]

      if school_calendar_step.present?
        school_calendar_steps_ids_marked_for_destruction << school_calendar_step.id if step_params['_destroy'] == 'true'
        @school_calendar_steps[school_calendar_step.id] = { start_at: school_calendar_step.start_at, end_at: school_calendar_step.end_at }

        update_school_calendar_step!(school_calendar, step_params, index)
      else
        create_school_calendar_step!(school_calendar, step_params)
      end
    end

    set_correct_steps_to_relations(school_calendar, school_calendar_steps_ids_marked_for_destruction)
    destroy_school_calendar_steps_marked_for_destruction(school_calendar, school_calendar_steps_ids_marked_for_destruction)
  end

  def update_school_calendar_classroom_steps(school_calendar)
    @school_calendar_classroom_steps = {}
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
            @school_calendar_classroom_steps[school_calendar_classroom_step.id] = {
              start_at: school_calendar_classroom_step.start_at,
              end_at: school_calendar_classroom_step.end_at
            }

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

      set_correct_classroom_steps_to_relations(school_calendar_classroom, school_calendar_classroom_steps_ids_marked_for_destruction)
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
    SchoolCalendarStep.create!(school_calendar: school_calendar,
                               start_at: step_params['start_at'],
                               end_at: step_params['end_at'],
                               start_date_for_posting: step_params['start_date_for_posting'],
                               end_date_for_posting: step_params['end_date_for_posting'])
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

  def set_correct_steps_to_relations(school_calendar, school_calendar_steps_ids_marked_for_destruction)
    school_calendar.steps.each do |step|
      SchoolCalendarStep.reflect_on_all_associations(:has_many).each do |association|
        next if [:audits, :associated_audits, :ieducar_api_exam_postings].include?(association.name)
        next if association.options[:through].present?

        step.send(association.name).each do |relation|
          if association.name == :descriptive_exams
            start_at = @school_calendar_steps[relation.school_calendar_step_id][:start_at]
            end_at = @school_calendar_steps[relation.school_calendar_step_id][:end_at]
            year = start_at.year

            school_calendar_step_id = SchoolCalendarStep.by_school_calendar_id(school_calendar.id)
                                                        .where.not(id: school_calendar_steps_ids_marked_for_destruction)
                                                        .started_after_and_before(start_at).started_after_and_before(end_at)
                                                        .active.first.try(:id)
          else
            school_calendar_step_id = SchoolCalendarStep.by_school_calendar_id(school_calendar.id)
                                                        .where.not(id: school_calendar_steps_ids_marked_for_destruction)
                                                        .started_after_and_before(relation.recorded_at).active.first.try(:id)
          end

          if school_calendar_step_id.present?
            if school_calendar_step_id != relation.school_calendar_step_id
              move_to_other_step(relation, step, association.name, school_calendar_step_id)
            end
          else
            year ||= relation.recorded_at.year

            move_to_inactive_step(relation, step, association.name, year)
          end
        end
      end
    end
  end

  def move_to_other_step(relation, step, association_name, school_calendar_step_id)
    relation.school_calendar_step_id = school_calendar_step_id
    relation.unity_id = step.school_calendar.unity_id if association_name == :conceptual_exams
    relation.save!(validate: false)
  end

  def move_to_inactive_step(relation, step, association_name, year)
    school_calendar_step_id = SchoolCalendarStep.by_school_calendar_id(step.school_calendar_id).by_step_year(year).inactive.first.try(:id)

    if school_calendar_step_id.blank?
      school_calendar_step_id = SchoolCalendarStep.create(
        school_calendar_id: step.school_calendar_id,
        start_at: Date.new(year, 1, 1),
        end_at: Date.new(year, 12, 31),
        start_date_for_posting: Date.new(year, 1, 1),
        end_date_for_posting: Date.new(year, 12, 31),
        active: false
      ).id
    end

    move_to_other_step(relation, step, association_name, school_calendar_step_id)
  end

  def set_correct_classroom_steps_to_relations(school_calendar_classroom, school_calendar_classroom_steps_ids_marked_for_destruction)
    school_calendar_classroom.classroom_steps.each do |step|
      SchoolCalendarClassroomStep.reflect_on_all_associations(:has_many).each do |association|
        next if [:audits, :associated_audits, :ieducar_api_exam_postings].include?(association.name)
        next if association.options[:through].present?

        step.send(association.name).each do |relation|
          if association.name == :descriptive_exams
            start_at = @school_calendar_classroom_steps[relation.school_calendar_classroom_step_id][:start_at]
            end_at = @school_calendar_classroom_steps[relation.school_calendar_classroom_step_id][:end_at]
            year = start_at.year

            classroom_step_id = SchoolCalendarClassroomStep.by_school_calendar_id(school_calendar_classroom.school_calendar.id)
                                                           .where.not(id: school_calendar_classroom_steps_ids_marked_for_destruction)
                                                           .started_after_and_before(start_at).started_after_and_before(end_at)
                                                           .active.first.try(:id)
          else
            classroom_step_id = SchoolCalendarClassroomStep.by_school_calendar_id(school_calendar_classroom.school_calendar.id)
                                                           .where.not(id: school_calendar_classroom_steps_ids_marked_for_destruction)
                                                           .started_after_and_before(relation.recorded_at).active.first.try(:id)
          end

          if classroom_step_id.present?
            if classroom_step_id != relation.school_calendar_classroom_step_id
              move_to_other_classroom_step(relation, step, association.name, classroom_step_id)
            end
          else
            year ||= relation.recorded_at.year

            move_to_inactive_classroom_step(relation, step, association.name, year)
          end
        end
      end
    end
  end

  def move_to_other_classroom_step(relation, step, association_name, school_calendar_classroom_step_id)
    relation.school_calendar_classroom_step_id = school_calendar_classroom_step_id
    relation.unity_id = step.school_calendar.unity_id if association_name == :conceptual_exams
    relation.save!(validate: false)
  end

  def move_to_inactive_classroom_step(relation, step, association_name, year)
    classroom_step_id = SchoolCalendarClassroomStep.by_school_calendar_id(step.school_calendar_id).by_step_year(year).inactive.first.try(:id)

    if classroom_step_id.blank?
      classroom_step_id = SchoolCalendarClassroomStep.create(
        school_calendar_classroom_id: step.school_calendar_classroom_id,
        start_at: Date.new(year, 1, 1),
        end_at: Date.new(year, 12, 31),
        start_date_for_posting: Date.new(year, 1, 1),
        end_date_for_posting: Date.new(year, 12, 31),
        active: false
      ).id
    end

    move_to_other_classroom_step(relation, step, association_name, classroom_step_id)
  end
end
