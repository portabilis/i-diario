class AddAutomaticAbsencePostingToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :automatic_absence_posting, :boolean, default: false, null: false
  end
end
