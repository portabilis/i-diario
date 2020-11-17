class SchoolTermTypeUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, school_calendar_id = nil, school_calendar_classroom_id = nil)
    Entity.find(entity_id).using_connection do
      calendar = SchoolCalendar.find_by(id: school_calendar_id) ||
                 SchoolCalendarClassroom.find_by(id: school_calendar_classroom_id)

      return if calendar.blank?

      steps_number = calendar.steps.size
      description = calendar.step_type_description

      begin
        SchoolTermType.find_or_initialize_by(description: description).tap do |school_term_type|
          school_term_type.steps_number = steps_number

          new_record = school_term_type.new_record?

          school_term_type.save! if school_term_type.changed?

          if new_record
            1.upto(steps_number) do |step_number|
              SchoolTermTypeStep.create(school_term_type_id: school_term_type.id, step_number: step_number)
            end
          else
            SchoolTermTypeStep.where(school_term_type_id: school_term_type.id)
                              .where('step_number > :steps_number', steps_number: steps_number)
                              .destroy_all
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
