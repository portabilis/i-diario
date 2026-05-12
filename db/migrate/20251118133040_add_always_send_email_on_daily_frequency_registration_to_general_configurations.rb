class AddAlwaysSendEmailOnDailyFrequencyRegistrationToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :always_send_email_on_daily_frequency_registration, :boolean, default: false
  end
end
