namespace :entity do
  desc "Update Descriptive Exams School Calendar Step"
  task update_descriptive_exams_school_calendar_step: :environment do
    descriptive_exams_school_calendar_step_updater = DescriptiveExamsSchoolCalendarStepUpdater.new(ENV)

    descriptive_exams_school_calendar_step_updater.update

    puts descriptive_exams_school_calendar_step_updater.status
  end
end
