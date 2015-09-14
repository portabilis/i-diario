namespace :entity do
  desc "Update Avaliations Test Setting"
  task update_avaliations_test_setting: :environment do
    avaliations_test_setting_updater = AvaliationsTestSettingUpdater.new(ENV)

    avaliations_test_setting_updater.update

    puts avaliations_test_setting_updater.status
  end
end
