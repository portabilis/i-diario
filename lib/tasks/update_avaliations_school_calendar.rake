namespace :entity do
  desc "Update Avaliations School Calendar"
  task update_avaliations_school_calendar: :environment do
    avaliations_school_calendar_updater = AvaliationsSchoolCalendarUpdater.new(ENV)

    avaliations_school_calendar_updater.update

    puts avaliations_school_calendar_updater.status
  end
end
