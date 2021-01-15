class SchoolTermTypeUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, school_calendar_id = nil, school_calendar_classroom_id = nil)
    Entity.find(entity_id).using_connection do
      calendar = SchoolCalendar.find_by(id: school_calendar_id) ||
                 SchoolCalendarClassroom.find_by(id: school_calendar_classroom_id)

      return if calendar.blank?

      steps_number = calendar.steps.size
      description = "#{calendar.step_type_description} (#{steps_number} #{'etapa'.pluralize(steps_number)})"

      begin
        SchoolTermType.find_or_initialize_by(description: description).tap do |school_term_type|
          school_term_type.steps_number = steps_number

          new_record = school_term_type.new_record?

          school_term_type.save! if school_term_type.changed?

          create_or_discard_step(new_record, school_term_type, steps_number)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end

  def create_or_discard_step(new_record, school_term_type, steps_number)
    if new_record
      1.upto(steps_number) do |step_number|
        if (discarded_step = SchoolTermTypeStep.discarded.find_by(school_term_type_id: school_term_type.id,
                                                                  step_number: step_number))
          discarded_step.undiscard
        else
          SchoolTermTypeStep.create(school_term_type_id: school_term_type.id, step_number: step_number)
        end
      end
    else
      SchoolTermTypeStep.where(school_term_type_id: school_term_type.id)
                        .where('step_number > :steps_number', steps_number: steps_number)
                        .discard_all
    end
  end
end
