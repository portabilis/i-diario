class AddGroupedTeacherProfileToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :grouped_teacher_profile, :boolean, default: false, null: false
  end
end
