class AddDoNotSendJustifiedAbsenceIntoGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :do_not_send_justified_absence, :boolean, default: false
  end
end
