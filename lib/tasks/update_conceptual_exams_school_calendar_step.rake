namespace :entity do
  desc "Update Conceptual Exams School Calendar Step"
  task update_conceptual_exams_school_calendar_step: :environment do
    conceptual_exams_school_calendar_step_updater = ConceptualExamsSchoolCalendarStepUpdater.new(ENV)

    conceptual_exams_school_calendar_step_updater.update

    puts conceptual_exams_school_calendar_step_updater.status
  end
end
